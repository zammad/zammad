class Sequencer
  class Unit
    module Common
      class FallbackProvider < Sequencer::Unit::Base

        def process
          provides = self.class.provides
          raise 'Only one provide attribute possible' if provides.size != 1

          attribute = provides.shift
          return if state.provided?(attribute)

          result = fallback

          # don't store nil values which are default anyway
          return if result.nil?

          state.provide(attribute, result)
        end

        private

        def fallback
          raise 'Missing implementation of fallback method'
        end
      end
    end
  end
end
