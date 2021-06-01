# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Common
        module Model
          module FindBy
            class UserAttributes < Sequencer::Unit::Import::Common::Model::Lookup::Attributes

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
