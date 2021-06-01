# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Ldap
        module User
          module Skip
            class MissingMandatory < Sequencer::Unit::Import::Common::Model::Skip::MissingMandatory::Mapped
              private

              def mandatory
                [:login]
              end
            end
          end
        end
      end
    end
  end
end
