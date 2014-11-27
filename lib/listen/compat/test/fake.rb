require 'listen/compat/wrapper'

module Listen
  module Compat
    module Test
      class Fake < Listen::Compat::Wrapper::Common
        def self.fire_events(thread, *args)
          processed = _processed(thread)
          processed.pop until processed.empty?
          _events(thread) << args
          processed.pop
        end

        def self.collect_instances(thread)
          return [] if _instances(thread).empty?
          result = []
          result << _instances(thread).pop until _instances(thread).empty?
          result
        end

        attr_reader :directories

        def initialize
          thread = Thread.current

          thread[:fake_instances] = Queue.new
          thread[:fake_events] = Queue.new
          thread[:fake_processed_events] = Queue.new

          Fake._instances(thread) << self
        end

        private

        def _start_and_wait(*args, &block)
          @directories = args[0..-2]
          loop do
            ev = Fake._events(Thread.current).pop
            block.call(*ev)
            Fake._processed(Thread.current) << ev
          end
        end

        def _stop
        end

        def self._processed(thread)
          thread[:fake_processed_events]
        end

        def self._events(thread)
          thread[:fake_events]
        end

        def self._instances(thread)
          thread[:fake_instances]
        end
      end
    end
  end
end
