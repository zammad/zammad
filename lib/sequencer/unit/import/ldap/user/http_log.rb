class Sequencer
  class Unit
    module Import
      module Ldap
        module User
          class HttpLog < Import::Common::Model::HttpLog
            private

            def facility
              'ldap'
            end
          end
        end
      end
    end
  end
end
