# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module ObjectAttribute
          module AttributeType
            class Decimal < Sequencer::Unit::Import::Zendesk::ObjectAttribute::AttributeType::Text
            end
          end
        end
      end
    end
  end
end
