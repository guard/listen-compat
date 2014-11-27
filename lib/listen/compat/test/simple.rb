module Listen
  module Compat
    module Test
      # Simple stub for a real Listen instance, which just forwards events
      class Simple
        def self.to(*_args)
          Simple.new
        end

        def start
        end
      end
    end
  end
end
