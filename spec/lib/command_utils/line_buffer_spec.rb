require 'command_utils/line_buffer'

RSpec.describe CommandUtils::LineBuffer do

  let(:receiver) do
    r =double(:receiver)
    allow(r).to receive(:log).with(String)
    r
  end

  let(:prefix) { 'prefix' }

  subject do
    CommandUtils::LineBuffer.new(
      receiver.method(:log),
      prefix,
      )
  end

  context '#write' do

    it 'does not call receiver#log if there was no \n' do
      expect(receiver).not_to receive(:log)
      10.times{subject.write('oauaoe')}
    end

    it 'calls receiver#log when a \n was received' do
      expect(receiver).to receive(:log)
      subject.write("aoeua\n")
    end

    it 'it caches string after \n for next call' do
      expect(receiver).to receive(:log).with("#{prefix}aaaa")
      subject.write("aaaa\nbbbb")
      expect(receiver).to receive(:log).with("#{prefix}bbbbcccc")
      subject.write("cccc\nbbbb")
    end

    it 'prefix log messages' do
      expect(receiver).to receive(:log).with("#{prefix}aaaa")
      subject.write("aaaa\n")
    end

  end

  context '#flush' do

    it 'calls method with remaining buffer' do
      expect(receiver).to receive(:log).with("#{prefix}aaaa")
      subject.write("aaaa\nbbbb")
      expect(receiver).to receive(:log).with("#{prefix}bbbb")
      subject.flush
    end

  end

end
