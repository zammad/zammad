# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Common::Tag::Add < Sequencer::Unit::Base

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
