# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Common
      module Tag
        class Add < Sequencer::Unit::Base

          uses :model_class, :instance, :item, :user_id

          def process
            ::Tag.tag_add(
              object:        model_class.name,
              o_id:          instance.id,
              item:          item,
              created_by_id: user_id,
            )
          end
        end
      end
    end
  end
end
