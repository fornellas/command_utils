require_relative 'command_utils/non_zero_status'
require_relative 'command_utils/line_buffer'

# Class to assist calling external commands, while processing its output and return code.
# All methods which execute given command, raise NonZeroStatus if its return is not 0.
class CommandUtils

  # Takes command in same format supported by Process#spawn.
  def initialize *command
    @command = command
    yield self if block_given?
  end

  # Execute command, yielding to given block, each time there is output available.
  # stream:: either +:stdout+ or +:stderr+.
  # data:: data read from respective stream.
  def each_output # :yields: stream, data
    run do
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
          yield label, io.read
        end
      end
    end
  end

  # Wrapper for CommandUtils#each_output
  def self.each_output *command, &block # :yields: stream, data
    self.new(*command).each_output(&block)
  end

  # Execute command, yielding to given block, each time there is a new line available.
  # stream:: either +:stdout+ or +:stderr+.
  # data:: data read from respective stream.
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

  # Wrapper for CommandUtils#each_line
  def self.each_line *command, &block # :yields: stream, data
    self.new(*command).each_line(&block)
  end

  # Execute command, logging its output, line buffered, to given Logger object.
  # Must receive a hash, containing at least:
  # +:logger+:: Logger instance.
  # +:stdout_level+:: Logger level to log stdout.
  # +:stderr_level+:: Logger level to log stderr.
  # and optionally:
  # +:stdout_prefix+:: Prefix to use for all stdout messages.
  # +:stderr_prefix+:: Prefix to use for all stderr messages.
  def logger_exec options
    each_line do |stream, data|
      level = options["#{stream}_level".to_sym]
      prefix = options["#{stream}_prefix".to_sym]
      options[:logger].send(level, "#{prefix}#{data}")
    end
  end

  # Wrapper for CommandUtils@logger_exec
  def self.logger_exec command, options
    self.new(command).logger_exec(options)
  end

  private

  def run
    spawn
    yield
    process_status
  end

  def spawn
    @stdout_read, @stdout_write = IO.pipe
    @stderr_read, @stderr_write = IO.pipe
    @pid = Process.spawn(
      *@command,
      in: :close,
      out: @stdout_write.fileno,
      err: @stderr_write.fileno,
      close_others: true,
      )
    @stdout_write.close
    @stderr_write.close
  end

  def process_status
    Process.wait @pid
    unless (status = $?.exitstatus) == 0
      raise NonZeroStatus.new(
        "Command exited with #{status}.",
        status,
        @command
        )
    end
  end
end
