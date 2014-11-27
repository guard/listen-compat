require 'fileutils'
require 'pathname'
require 'tmpdir'

require 'listen/compat/wrapper'

# TODO: since we're using RSpec now, this is not necessary
module MockListen
  class Listener
    def initialize(*args)
      @calls = Queue.new
      @calls << [__method__, *args]
      MockListen.add_instance(self)
    end

    def method_missing(meth, *args, &_block)
      @calls << [meth, *args]
    end

    def calls
      MockListen.dump(@calls)
    end
  end

  class << self
    def dump(queue)
      res = []
      res << queue.pop until queue.empty?
      res
    end

    def setup_for_tests
      Listen::Compat::Wrapper.listen_module = MockListen
      @calls = Queue.new
      @mocks = Queue.new
      @responses = {}
      @called = []
    end

    def reset_for_tests
      instance_variables.each do |var|
        instance_variable_set(var, :unset)
      end
    end

    # setup actions
    attr_reader :responses

    def add_instance(obj)
      @mocks << obj
    end

    # Get results
    def instances
      MockListen.dump(@mocks)
    end

    def calls
      MockListen.dump(@calls)
    end

    def method_missing(meth, *args, &block)
      @calls << [meth, *args]
      block = responses[meth]
      block.call(*args) unless block.nil?
    end
  end
end

module DelayedInterruptHelper
  def delayed_interrupt(&block)
    th = Thread.new(&block)
    sleep 0.1
    sleep 0.1 while (status = th.status) == 'running'
    th.raise Interrupt
    th.join
    status
  end
end

RSpec.describe Listen::Compat::Wrapper::Ancient do
  let(:wrapper) { Listen::Compat::Wrapper.create('0.1.0') }

  before do
    MockListen.setup_for_tests
    MockListen.responses[:start!] = proc { fail Interrupt }
  end

  after do
    MockListen.reset_for_tests
  end

  it { is_expected.to be_a described_class }

  it 'readonly dirs are avoided' do
    tmpdir, result = Dir.mktmpdir do |dir|
      ro_dir = File.join(dir, 'foo')
      FileUtils.mkdir(ro_dir, mode: 0444)
      [dir, wrapper.watchable_directories([dir, ro_dir, '.'])]
    end

    expect(result).to eq([tmpdir, '.'])
  end

  it 'passes parameters to listen' do
    wrapper.listen('.', {})
    expect(MockListen.instances[0].calls[0]).to eq([:initialize, '.', {}])
  end

  it 'calls start' do
    wrapper.listen('.', {})
    expect(MockListen.instances[0].calls[1]).to eq([:start!])
  end

  it 'does not call stop' do
    wrapper.listen('.', {})
    expect(MockListen.calls).to eq([])
  end
end

RSpec.describe Listen::Compat::Wrapper::Old do
  include DelayedInterruptHelper

  let(:wrapper) { Listen::Compat::Wrapper.create('2.7.6') }

  before do
    MockListen.setup_for_tests
    MockListen.responses[:to] = proc { |*args| MockListen::Listener.new(*args) }
  end

  after do
    MockListen.reset_for_tests
  end

  it { is_expected.to be_a described_class }

  it 'passes parameters to listen' do
    delayed_interrupt { wrapper.listen('.', {}) }
    expect(MockListen.calls[0]).to eq([:to, '.', {}])
  end

  it 'calls start' do
    delayed_interrupt { wrapper.listen('.', {}) }
    expect(MockListen.instances[0].calls[1]).to eq([:start])
  end

  it 'sleeps after start' do
    status = delayed_interrupt { wrapper.listen('.', {}) }
    expect(status).to eq('sleep')
  end

  it 'calls stop' do
    delayed_interrupt { wrapper.listen('.', {}) }
    expect(MockListen.calls[1]).to eq([:stop])
  end
end

RSpec.describe Listen::Compat::Wrapper::Stale do
  include DelayedInterruptHelper

  let(:wrapper) { Listen::Compat::Wrapper.create('2.7.11') }

  before do
    MockListen.setup_for_tests
    MockListen.responses[:to] = proc { |*args| MockListen::Listener.new(*args) }
  end

  after do
    MockListen.reset_for_tests
  end

  it { is_expected.to be_a described_class }

  it 'calls start' do
    delayed_interrupt { wrapper.listen('.', {}) }
    expect(MockListen.instances[0].calls[1]).to eq([:start])
  end

  it 'sleeps after start' do
    status = delayed_interrupt { wrapper.listen('.', {}) }
    expect(status).to eq('sleep')
  end

  it 'calls stop' do
    delayed_interrupt { wrapper.listen('.', {}) }
    expect(MockListen.calls[1]).to eq([:stop])
  end
end

RSpec.describe Listen::Compat::Wrapper::Current do
  include DelayedInterruptHelper

  let(:wrapper) { Listen::Compat::Wrapper.create('2.7.12') }

  before do
    MockListen.setup_for_tests
    MockListen.responses[:to] = proc { |*args| MockListen::Listener.new(*args) }
  end

  after do
    MockListen.reset_for_tests
  end

  it { is_expected.to be_a described_class }

  it 'passes parameters to listen' do
    delayed_interrupt { wrapper.listen('.', {}) }
    expect(MockListen.calls[0]).to eq([:to, '.', {}])
  end

  it 'calls start' do
    delayed_interrupt { wrapper.listen('.', {}) }
    expect(MockListen.instances[0].calls[1]).to eq([:start])
  end

  it 'sleeps after start' do
    status = delayed_interrupt { wrapper.listen('.', {}) }
    expect(status).to eq('sleep')
  end

  it 'calls stop' do
    delayed_interrupt { wrapper.listen('.', {}) }
    expect(MockListen.calls[1]).to eq([:stop])
  end
end
