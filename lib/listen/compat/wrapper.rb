require 'listen/compat/version' # just for convenience

module Listen
  module Compat
    # Tries to require Listen using rubygems or vendored version
    module Loader
      module_function

      def load!
        defined?(gem) ? try_rubygems : try_without_rubygems
      end

      def try_rubygems
        gem 'listen', '>= 1.1.0', '< 3.0.0'
        require 'listen'
      rescue LoadError, Gem::LoadError => e
        e.message.replace(format("%s\n%s", e.message, msg_about_gem_install))
        raise
      end

      def compatible_version
        !older_than_193?  ?  '~> 2.7' : '~> 1.1'
      end

      def older_than_193?
        Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('1.9.3')
      end

      def msg_about_gem_install
        format("Run \"gem install listen --version '%s'\" to get it.",
               compatible_version)
      end
    end

    module Wrapper
      class << self
        attr_writer :listen_module
        attr_accessor :wrapper_class

        def listen_module
          @listen_module ||= Listen
        end
      end

      # History of bugs/workarounds:
      #
      # Ancient (< 2.0.0) - very old version
      #   - uses start!
      #   - polling method
      #   - start method blocks
      #   - fails on readonly directories and files
      #
      # Old (>= 2.0.0) - major API change
      #   - uses Celluloid, so shutdown/thread handling is different
      #   - start returns a thread (not sure if 2.0.0 or later)
      #   - sleep is needed to block
      #   = 2.7.6 - start() returns adapter thread (instead of wait_thread)
      #
      # Stale (>= 2.7.7) - broke mutliple dir handling on OSX (#243)
      #   - devious threads hack in Sass works by accident (!)
      #   = 2.7.11 - last version where start still returns a thread
      #
      # Current (>= 2.7.12)- start() no longer returns a thread
      #   - fixed multiple dir handling (#243)
      #   = 2.8.0 - current version

      # "Expected" functionality from any Listen version
      class Common
        # Run listen continously to monitor changes and gracefully terminate
        # on Ctrl-C
        def listen(*args, &block)
          _start_and_wait(*args, &block)
        rescue Interrupt
          _stop
        end

        protected

        # Overridable method so a fake implementation can be used in tests
        def _listen_module
          Wrapper.listen_module
        end

        # Overridable method so a fake implementation can be used in tests
        def _listen_class
          _listen_module::Listener
        end

        private

        # Run listen continuously, regardless whether it blocks or starts
        # a background thread
        def _start_and_wait(*args, &block)
          _listen_module.to(*args, &block).start
          sleep
        end

        # Gracefully shutdown Listen after a Ctrl-C, join threads, etc.
        def _stop
          _listen_module.stop
        end
      end

      # Workarounds for pre 2.0 versions of Listen
      class Ancient < Common
        NEXT_VERSION = Gem::Version.new('2.0.0')

        # A Listen version prior to 2.0 will write a test file to a directory
        # to see if a watcher supports watching that directory. That breaks
        # horribly on read-only directories, so we filter those out.
        def watchable_directories(directories)
          directories.select { |d| ::File.directory?(d) && ::File.writable?(d) }
        end

        def listen(*args, &block)
          options     = args.last.is_a?(Hash) ? args.pop : {}
          # Note: force_polling is a method here (since Listen 2.0.0 it's an
          # option passed to Listen.new)
          poll = options[:force_polling]

          directories = watchable_directories(args.flatten)

          # Don't optimize this out because of Ruby 1.8
          args = directories
          args << options

          listener = _listen_class.new(*args, &block)
          listener.force_polling(true) if poll
          listener.start!
        rescue Interrupt
        end
      end

      # >= 2.0.0, <= 2.7.6
      class Old < Common
        NEXT_VERSION = Gem::Version.new('2.7.7')
      end

      # >= 2.7.7, <= 2.7.11
      class Stale < Common
        NEXT_VERSION = Gem::Version.new('2.7.12')

        # Work around guard/listen#243 (>= v2.7.9, < v2.8.0)
        def _start_and_wait(*args, &block)
          options = args.pop if args.last.is_a?(Hash)
          listeners = args.map do |dir|
            _listen_module.to(dir, options, &block)
          end
          listeners.map(&:start)
          sleep
        end
      end

      # >= 2.7.12, <= 2.8.0
      class Current < Common
        NEXT_VERSION = Gem::Version.new('2.99.99')
      end

      # Returns a wrapper matching the listen version
      # @param version_string overrides detection (e.g. for testing)
      def self.create(version_string = nil)
        return Wrapper.wrapper_class.new if Wrapper.wrapper_class

        version = Gem::Version.new(version_string || _detect_listen_version)

        [Ancient, Old, Stale, Current].each do |klass|
          return klass.new if version < klass.const_get('NEXT_VERSION')
        end
      end

      private

      def self._detect_listen_version
        Loader.load!
        require 'listen/version'
        Listen::VERSION
      end
    end
  end
end
