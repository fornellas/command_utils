require_relative 'command_utils/line_buffer'

# Class to assist calling external commands, while processing its output and return code.
class CommandUtils

  # PID of currently running process.
  attr_reader :pid

  #  call-seq:
  #    new([env,] command...)
  #
  # Takes command in same format supported by Process#spawn.
  def initialize *args
    first = args.first
    if first.respond_to? :to_hash
      @env = args.shift.to_hash
      @command = args
    else
      @env = nil
      @command = args
    end
    yield self if block_given?
  end

  # Execute command, yielding to given block, each time there is output available (not line buffered):
  # stream:: either +:stdout+ or +:stderr+.
  # data:: data read from respective stream.
  # Raises CommandUtils::StatusError class exception if command execution is not successfull.
  def each_output &block # :yields: stream, data
    spawn
    begin
      loop do
        io_list = [@stdout_read, @stderr_read].keep_if{|io| not io.closed?}
        break if io_list.empty?
        IO.select(io_list).first.each do |io|
          if io.eof?
            io.close
            next
          end
          label = case io
          when @stdout_read
            :stdout
          when @stderr_read
            :stderr
          end
          buffer = ''
          loop do
            begin
              buffer += io.read_nonblock(io.stat.blksize)
            rescue EOFError
              io.close
              break
            rescue IO::EAGAINWaitReadable
              break
            end
          end
          yield label, buffer
        end
      end
    end
    process_status
  end

  #  call-seq:
  #    each_output([env,] command...) { |stream, data| ... }
  #
  # Wrapper for CommandUtils#each_output
  def self.each_output *args, &block # :yields: stream, data
    self.new(*args).each_output(&block)
  end

  # Execute command, yielding to given block, each time there is a new line available (does line buffering):
  # stream:: either +:stdout+ or +:stderr+.
  # data:: data read from respective stream.
  # Raises CommandUtils::StatusError class exception if command execution is not successfull.
  def each_line &block # :yields: stream, data
    stdout_lb = LineBuffer.new(
      proc do |data|
        block.call :stdout, data
      end
      )
    stderr_lb = LineBuffer.new(
      proc do |data|
        block.call :stderr, data
      end
      )
    each_output do |stream, data|
      case stream
      when :stdout
        stdout_lb.write data
      when :stderr
        stderr_lb.write data
      end
    end
    stdout_lb.flush
    stderr_lb.flush
  end

  #  call-seq:
  #    each_line([env,] command...) { |stream, data| ... }
  #
  # Wrapper for CommandUtils#each_line
  def self.each_line *args, &block # :yields: stream, data
    self.new(*args).each_line(&block)
  end

  # Execute command, logging its output, line buffered, to given Logger object.
  # Must receive a hash, containing at least:
  # +:logger+:: Logger instance.
  # +:stdout_level+:: Logger level to log stdout.
  # +:stderr_level+:: Logger level to log stderr.
  # and optionally:
  # +:stdout_prefix+:: Prefix to use for all stdout messages.
  # +:stderr_prefix+:: Prefix to use for all stderr messages.
  # Raises CommandUtils::StatusError class exception if command execution is not successfull.
  def logger_exec options
    each_line do |stream, data|
      level = options["#{stream}_level".to_sym]
      prefix = options["#{stream}_prefix".to_sym]
      options[:logger].send(level, "#{prefix}#{data}")
    end
  end

  #  call-seq:
  #    logger_exec([env,] command..., options)
  #
  # Wrapper for CommandUtils@logger_exec
  def self.logger_exec *args, options
    self.new(*args).logger_exec(options)
  end

  private

  # Process.spawn a new process with @env and @command.
  #
  # Sets @pid, @stdout_write and @stderr_write.
  def spawn
    @stdout_read, @stdout_write = IO.pipe
    @stderr_read, @stderr_write = IO.pipe
    spawn_args = if @env
      [@env] + @command
    else
      @command
    end
    @pid = Process.spawn(
      *spawn_args,
      in: :close,
      out: @stdout_write.fileno,
      err: @stderr_write.fileno,
      close_others: true,
      )
    @stdout_write.close
    @stderr_write.close
  end

  # Parent class for all status errors.
  class StatusError < StandardError
    # Process::Status
    attr_accessor :status
    # Command as passed to Process#spawn
    attr_accessor :command
    def initialize message, status, command
      super message
      @status, @command = status, command
    end
  end

  # Raised when process exited with non zero status.
  class NonZeroExit < StatusError ; end
  # Raised when process was signaled.
  class Signaled < StatusError ; end
  # Raised when process was stopped.
  class Stopped < StatusError ; end
  # Raised when process exited with unknown status.
  class Unknown < StatusError ; end

  # Wait for process termination, then process its status.
  def process_status
    pid, status = Process.wait2(@pid)
    if status.exited?
      unless status.exitstatus == 0
        message = "Command exited with #{status.exitstatus}."
        raise NonZeroExit.new(message, status, @command)
      end
    elsif status.signaled?
      message = "Command was signaled with #{status.termsig}."
      message += " Core dump generated." if status.coredump?
      raise Signaled.new(message, status, @command)
    elsif status.stopped?
      message = "Command was stopped with signal #{status.stopsig}, PID=#{pid}."
      raise Stopped.new(message, status, @command)
    else
      message = "Unknown return status."
      raise Unknown.new(message, status, @command)
    end
  end

end
