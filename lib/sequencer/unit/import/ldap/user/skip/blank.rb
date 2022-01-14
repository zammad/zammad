# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

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
