class CommandUtils

  # Line buffers writes, and calls method at each line
  class LineBuffer
    # Receive a method to call passing each line received. Optionally, specify a prefix.
    def initialize method, prefix=''
      @method = method
      @prefix = prefix
      @buffer = nil
    end

    # Receive a new chunk, and if a line is formed, call method.
    def write str
      @buffer ||= ''
      @buffer += str
      return unless @buffer.include? "\n"
      lines = @buffer.split("\n")
      @buffer = if @buffer.match("\n$")
        nil
      else
        lines.pop
      end
      lines.each do |line|
        @method.call(@prefix + line)
      end
    end

    # Send all buffer to method
    def flush
      return unless @buffer
      @method.call(@prefix + @buffer)
      @buffer = nil
    end

  end

end
