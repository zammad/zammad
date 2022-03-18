# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Zammad
  class Application
    module Initializer
      module DbPreflightCheck
        module Nulldb
          # no-op
          def self.perform; end
        end
      end
    end
  end
end
