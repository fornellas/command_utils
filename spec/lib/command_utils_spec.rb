require 'command_utils'
require 'logger'

RSpec.describe CommandUtils do

  context '#each_output' do

    it 'calls command with Process#spawn' do
      command = 'true'
      expect(Process).to receive(:spawn).with(command, any_args).and_call_original
      CommandUtils.new(command).each_output{}
    end

    it 'yields stdout' do
      c = CommandUtils.new('echo -n stdout')
      expect do |b|
        c.each_output(&b)
      end.to yield_successive_args([:stdout, 'stdout'])
    end

    it 'yields stderr' do
      c = CommandUtils.new('echo -n stderr 1>&2')
      expect do |b|
        c.each_output(&b)
      end.to yield_successive_args([:stderr, 'stderr'])
    end

    it 'yields both stdout and stderr' do
      c = CommandUtils.new('echo -n stdout ; echo -n stderr 1>&2')
      expect do |b|
        c.each_output(&b)
      end.to yield_successive_args(
        [:stdout, 'stdout'],
        [:stderr, 'stderr'],
        )
    end

    it 'raises if non 0 return' do
      c = CommandUtils.new('exit 1')
      expect do
        c.each_output{}
      end.to raise_error(CommandUtils::NonZeroStatus)
    end

  end

  context '#logger_exec' do

    let(:logger){instance_double(Logger)}

    it 'calls command with Process#spawn' do
      command = 'true'
      expect(Process).to receive(:spawn).with(command, any_args).and_call_original
      CommandUtils.new(command).logger_exec(
        logger: logger,
        stdout_level: :info,
        stderr_level: :error,
        )
    end

    it 'logs stdout' do
      expect(logger).to receive(:info).with('stdout')
      CommandUtils.new('echo -n stdout').logger_exec(
        logger: logger,
        stdout_level: :info,
        stderr_level: :error,
        )
    end

    it 'logs stderr' do
      expect(logger).to receive(:error).with('stderr')
      CommandUtils.new('echo -n stderr 1>&2').logger_exec(
        logger: logger,
        stdout_level: :info,
        stderr_level: :error,
        )
    end

    it 'logs both stdout and stderr' do
      expect(logger).to receive(:info).with('stdout')
      expect(logger).to receive(:error).with('stderr')
      CommandUtils.new('echo -n stdout ; echo -n stderr 1>&2').logger_exec(
        logger: logger,
        stdout_level: :info,
        stderr_level: :error,
        )
    end

    it 'prefix messages' do
      expect(logger).to receive(:info).with('stdout: stdout_message')
      expect(logger).to receive(:error).with('stderr: stderr_message')
      CommandUtils.new('echo -n stdout_message ; echo -n stderr_message 1>&2').logger_exec(
        logger: logger,
        stdout_level: :info,
        stderr_level: :error,
        stdout_prefix: 'stdout: ',
        stderr_prefix: 'stderr: ',
        )
    end

    it 'raises if non 0 return' do
      c = CommandUtils.new('exit 1')
      expect do
        c.logger_exec(
          logger: logger,
          stdout_level: :info,
          stderr_level: :error,
          )
      end.to raise_error(CommandUtils::NonZeroStatus)
    end

  end

  # context '#string_exec' do
  #   it 'returns hash with status, stdout and stderr'
  # end
end