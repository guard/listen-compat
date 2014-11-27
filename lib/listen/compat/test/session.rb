require 'listen/compat/wrapper'
require 'listen/compat/test/fake'
require 'listen/compat/test/simple'

module Listen
  module Compat
    module Test
      # Class for conveniently simulating interaction with Listen
      class Session
        # Calls the potentially blocking given block in a background thread
        def initialize(wrapper_class = nil, &block)
          Wrapper.wrapper_class = wrapper_class || Listen::Compat::Test::Fake
          Wrapper.listen_module = Listen::Compat::Test::Simple
          fail 'No block given!' unless block_given?
          @thread = Thread.new do
            begin
              block.call
            rescue StandardError => e
              msg = "\n\nERROR: Watched listen thread failed: %s: \n%s"
              STDERR.puts format(msg, e.message, e.backtrace * "\n")
              raise
            end
          end
        end

        # Simulate a Ctrl-C from the user
        def interrupt
          _wait_until_ready
          @thread.raise Interrupt
          @thread.join
        end

        # Simulate Listen events you want passed asynchronously to your callback
        def simulate_events(modified, added, removed)
          _wait_until_ready
          Fake.fire_events(@thread, *_events(modified, added, removed))
        end

        # Return a list of fake Listen instances actually created
        def instances
          @instances ||= Fake.collect_instances(@thread)
        end

        private

        def _events(modified, added, removed)
          [_abs_paths(modified), _abs_paths(added), _abs_paths(removed)]
        end

        def _abs_paths(paths)
          paths.map { |path| File.expand_path(path) }
        end

        def _wait_until_ready
          sleep 0.1
          sleep 0.1 while @thread.status == 'running'

          # Show error on crashes
          @thread.join if @thread.status.nil?

          return if @thread.status == 'sleep'

          fail "Unexpected thread state: #{@thread.status.inspect}"
        end
      end
    end
  end
end
