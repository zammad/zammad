class Sequencer
  class Unit
    module Import
      module Ldap
        module User
          module Skip
            class Blank < Sequencer::Unit::Import::Common::Model::Skip::Blank::Mapped
              private

              def ignore
                %i[login]
              end
            end
          end
        end
      end
    end
  end
end
