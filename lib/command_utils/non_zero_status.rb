class CommandUtils

  # Raised when executed command does not return 0
  class NonZeroStatus < RuntimeError

    # Command exit status
    attr_accessor :status
    # Command as passed to Process#spawn
    attr_accessor :command

    def initialize message, status, command
      super message
      @status, @command = status, command
    end

  end

end