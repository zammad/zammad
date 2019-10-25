module Zammad
  class Application
    class Initializer
      module DBPreflightCheck
        module Nulldb
          # no-op
          def self.perform; end
        end
      end
    end
  end
end
