require 'listen/compat/test/session'

class MyExampleApp
  attr_reader :changed

  def start_listening_for_changes
    listener = Listen::Compat::Wrapper.create

    directories = %w(foo bar baz)
    options = { force_polling: false }

    listener.listen(directories, options) do |modified, _added, _removed|
      @changed ||= []
      @changed += modified.map do |full_path|
        Pathname(full_path).relative_path_from(Pathname.pwd).to_s
      end
    end
  end
end

RSpec.describe MyExampleApp do
  it 'works' do
    myapp = MyExampleApp.new

    session = Listen::Compat::Test::Session.new do
      # put whatever code would cause Listen to block here:
      myapp.start_listening_for_changes
    end

    # simulate changes
    session.simulate_events(['foo.png'], [], [])

    # simulate the user stopping the listening with Ctrl-C
    session.interrupt

    # whatever tests to make you app's callback was called:
    expect(myapp.changed).to eq(%w(foo.png))
  end
end
