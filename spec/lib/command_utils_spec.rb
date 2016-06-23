require 'command_utils'
require 'logger'

RSpec.describe CommandUtils do

  it 'has #pid attribute' do
    expect(CommandUtils.new('true')).to respond_to(:pid)
  end

  context '#initialize' do

    it 'yields self if block given' do
      yielded_argument = nil
      returned_command_util = CommandUtils.new('true') do |block_command_uitl|
        yielded_argument = block_command_uitl
      end
      expect(yielded_argument).to eq(returned_command_util)
    end

  end

  context 'base method' do

    context '#each_output' do

      it 'calls command with #spawn' do
        command = 'true'
        instance = CommandUtils.new(command)
        expect(instance).to receive(:spawn).with(no_args).and_call_original
        instance.each_output{}
      end

      it 'calls #process_status' do
        command = 'true'
        instance = CommandUtils.new(command)
        expect(instance).to receive(:process_status).with(no_args).and_call_original
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
        end.to raise_error(CommandUtils::StatusError)
      end

      it 'raises exception if given block breaks' do
        c = CommandUtils.new('echo stdout ; exit 1')
        expect do
          c.each_output do |stream, data|
            break
          end
        end.to raise_error(CommandUtils::StatusError)
      end

    end

  end

  context 'top level methods' do

    before(:example) do
      expect_any_instance_of(CommandUtils).to receive(:each_output).and_call_original
    end

    context '#each_line' do

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

    end

    context '#logger_exec' do

      let(:logger){instance_double(Logger)}

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

    end
  end

  context 'class methods' do

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

  end

  context 'Private methods' do

    let(:stdout_output) { 'stdout_output' }
    let(:stderr_output) { 'stderr_output' }

    let(:command) { "echo -n #{stdout_output} ; echo -n #{stderr_output} 1>&2" }

    subject { CommandUtils.new(command) }

    context '#spawn' do

      context '@pid' do

        let(:fake_pid) { rand(32768) }

        it 'sets @pid' do
          expect(Process).to receive(:spawn).with(command, any_args).and_return(fake_pid)
          subject.instance_eval { spawn }
          expect(subject.instance_variable_get(:@pid)).to eq(fake_pid)
        end

      end

      context 'Process#spawn' do

        after(:example) do
          subject.instance_eval { spawn }
        end

        it 'calls Process#spawn' do
          expect(Process).
            to receive(:spawn).
            with(
              command,
              hash_including(
                in: :close,
                out: kind_of(Fixnum),
                err: kind_of(Fixnum),
                close_others: true,
              )
            )
        end

        context 'with environment' do

          let(:environment) { {'var' => 'value'} }

          subject { CommandUtils.new(environment, command) }

          it 'calls Process#spawn with environment' do
            expect(Process).to receive(:spawn).with(environment, command, any_args)
          end

        end

      end

      context 'output' do

        before(:example) do
          subject.instance_eval { spawn }
        end

        after(:example) do
          subject.instance_eval { process_status }
        end

        it 'redirects stdout to @stdout_read' do
          expect(subject.instance_eval { @stdout_read.read }).to eq(stdout_output)
        end

        it 'redirects stderr to @stderr_read' do
          expect(subject.instance_eval { @stderr_read.read }).to eq(stderr_output)
        end

      end

    end

    context '#process_status' do

      let(:fake_pid) { rand(32768) }

      let(:status) do
        instance_double('Process::Status')
      end

      before(:example) do
        expect(Process).to receive(:spawn).with(command, any_args).and_return(fake_pid)
        subject.instance_eval { spawn }
        expect(Process).to receive(:wait2).with(fake_pid, any_args).and_return([fake_pid, status])
        [:exited?, :signaled?, :stopped?].each do |message|
          allow(status).to receive(message).with(no_args).and_return(false)
        end
      end

      context 'process exited' do

        before(:example) do
          expect(status).to receive(:exited?).with(no_args).and_return(true)
        end

        context 'with 0' do

          before(:example) do
            expect(status).to receive(:exitstatus).at_least(:once).with(no_args).and_return(0)
          end

          it 'does not raise' do
            expect do
              subject.instance_eval { process_status }
            end.not_to raise_error
          end

        end

        context 'with non 0' do

          before(:example) do
            expect(status).to receive(:exitstatus).at_least(:once).with(no_args).and_return(33)
          end

          it 'raises' do
            expect do
              subject.instance_eval { process_status }
            end.to raise_error CommandUtils::NonZeroExit
          end
        end

      end

      context 'process was signaled' do

        let(:termsig) { 15 }

        before(:example) do
          expect(status).to receive(:signaled?).with(no_args).and_return(true)
          expect(status).to receive(:termsig).with(no_args).and_return(termsig)
          allow(status).to receive(:coredump?).with(no_args).and_return(false)
        end

        it 'raises' do
          expect do
            subject.instance_eval { process_status }
          end.to raise_error CommandUtils::Signaled
        end

        it 'informs received signal' do
          begin
            subject.instance_eval { process_status }
          rescue CommandUtils::Signaled
            expect($!.message).to match(Regexp.new(termsig.to_s))
          end
        end

        context 'core dump generated' do

          before(:example) do
            expect(status).to receive(:coredump?).with(no_args).and_return(true)
          end

          it 'informs it' do
            begin
              subject.instance_eval { process_status }
            rescue CommandUtils::Signaled
              expect($!.message).to match(/core/i)
            end
          end

        end

      end

      context 'process was stopped' do

        let(:stopsig) { 17 }

        before(:example) do
          expect(status).to receive(:stopped?).with(no_args).and_return(true)
          expect(status).to receive(:stopsig).with(no_args).and_return(stopsig)
        end

        it 'raises' do
          expect do
            subject.instance_eval { process_status }
          end.to raise_error CommandUtils::Stopped
        end

        it 'informs signal' do
          begin
            subject.instance_eval { process_status }
          rescue CommandUtils::Stopped
            expect($!.message).to match(Regexp.new(stopsig.to_s))
          end
        end

      end

      context 'other statuses' do

        it 'raises' do
          expect do
            subject.instance_eval { process_status }
          end.to raise_error CommandUtils::Unknown
        end

      end

    end

  end

end
