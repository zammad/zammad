# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module ObjectAttribute
          module AttributeType
            class Dropdown < Sequencer::Unit::Import::Zendesk::ObjectAttribute::AttributeType::Select
            end
          end
        end
      end
    end
  end
end
