class Sequencer
  class Unit
    module Import
      module Ldap
        module User
          module Lookup
            class Attributes < Sequencer::Unit::Import::Common::Model::Lookup::Attributes
              private

              def attributes
                %i[login email]
              end
            end
          end
        end
      end
    end
  end
end
