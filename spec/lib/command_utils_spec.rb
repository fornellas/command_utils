require 'command_utils'
require 'logger'

RSpec.describe CommandUtils do

  context '#each_output' do

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

    it 'logs output to logger'
    
  end

  # context '#string_exec' do
  #   it 'returns hash with status, stdout and stderr'
  # end
end