# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

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
