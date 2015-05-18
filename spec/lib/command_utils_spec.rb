require 'command_utils'
require 'logger'

RSpec.describe CommandUtils do
  context '#initialize' do

    it 'yields self if block given' do
      yielded_argument = nil
      returned_command_util = CommandUtils.new('true') do |block_command_uitl|
        yielded_argument = block_command_uitl
      end
      expect(yielded_argument).to eq(returned_command_util)
    end

  end

  context '#each_output' do

    it 'calls command with #spawn' do
      command = 'true'
      instance = CommandUtils.new(command)
      expect(instance).to receive(:spawn).with(no_args).and_call_original
      instance.each_output{}
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

  context '::each_output' do

    it 'calls #each_output' do
      command = 'true'
      block = proc{}
      command_utils_instance_double = instance_double('CommandUtils')
      expect(command_utils_instance_double).to receive(:each_output).with(no_args, &block)
      expect(CommandUtils).to receive(:new).with(command).and_return(command_utils_instance_double)
      CommandUtils.each_output(command, &block)
    end

  end

  context '#each_line' do

    it 'calls command with #spawn' do
      command = 'true'
      instance = CommandUtils.new(command)
      expect(instance).to receive(:spawn).with(no_args).and_call_original
      instance.each_line{}
    end

    it 'yields stdout' do
      c = CommandUtils.new('echo "line1\nline2"')
      expect do |b|
        c.each_line(&b)
      end.to yield_successive_args(
        [:stdout, "line1"],
        [:stdout, "line2"],
        )
    end

    it 'yields stderr' do
      c = CommandUtils.new('echo "line1\nline2" 1>&2')
      expect do |b|
        c.each_line(&b)
      end.to yield_successive_args(
        [:stderr, "line1"],
        [:stderr, "line2"],
        )
    end

    it 'yields both stdout and stderr' do
      c = CommandUtils.new('echo "line1\nline2" ; echo "line1\nline2" 1>&2')

      expect do |b|
        c.each_line(&b)
      end.to yield_successive_args(
        [:stdout, "line1"],
        [:stdout, "line2"],
        [:stderr, "line1"],
        [:stderr, "line2"],
        )
    end

    it 'raises if non 0 return' do
      c = CommandUtils.new('exit 1')
      expect do
        c.each_line{}
      end.to raise_error(CommandUtils::NonZeroStatus)
    end
  end

  context '::each_line' do

    it 'calls #each_line' do
      command = 'true'
      block = proc{}
      command_utils_instance_double = instance_double('CommandUtils')
      expect(command_utils_instance_double).to receive(:each_line).with(no_args, &block)
      expect(CommandUtils).to receive(:new).with(command).and_return(command_utils_instance_double)
      CommandUtils.each_line(command, &block)
    end

  end

  context '#logger_exec' do

    let(:logger){instance_double(Logger)}

    it 'calls command with #spawn' do
      command = 'true'
      instance = CommandUtils.new(command)
      expect(instance).to receive(:spawn).with(no_args).and_call_original
      instance.logger_exec(
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

  context '::logger_exec' do

    it "calls #logger_exec" do
      command = 'true'
      options = {
        logger: instance_double(Logger),
        stdout_level: :info,
        stderr_level: :error,
        }
      command_utils_instance_double = instance_double('CommandUtils')
      expect(command_utils_instance_double).to receive(:logger_exec).with(options)
      expect(CommandUtils).to receive(:new).with(command).and_return(command_utils_instance_double)
      CommandUtils.logger_exec(command, options)
    end

  end

  context 'Private methods' do

    context '#spawn' do

      it 'calls Process#spawn without environment' do
        command = 'true'
        instance = CommandUtils.new(command)
        expect(Process).to receive(:spawn).with(command, any_args).and_call_original
        instance.each_output{|stream,data|}
      end

      it 'calls Process#spawn with environment' do
        env = {'var' => 'value'}
        command = 'true'
        instance = CommandUtils.new(env, command)
        expect(Process).to receive(:spawn).with(env, command, any_args).and_call_original
        instance.each_output{|stream,data|}
      end

    end

  end

end
