# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module HasTags
  extend ActiveSupport::Concern

  included do
    before_destroy :tag_destroy
  end

=begin

add an tag to model

  model = Model.find(123)
  model.tag_add(name)

=end

  def tag_add(name, current_user_id = nil)
    Tag.tag_add(
      object:        self.class.to_s,
      o_id:          id,
      item:          name,
      created_by_id: current_user_id,
    )
  end

=begin

remove an tag of model

  model = Model.find(123)
  model.tag_remove(name)

=end

  def tag_remove(name, current_user_id = nil)
    Tag.tag_remove(
      object:        self.class.to_s,
      o_id:          id,
      item:          name,
      created_by_id: current_user_id,
    )
  end

=begin

tag list of model

  model = Model.find(123)
  tags = model.tag_list

=end

  def tag_list
    Tag.tag_list(
      object: self.class.to_s,
      o_id:   id,
    )
  end

=begin

destroy all tags of an object

  model = Model.find(123)
  model.tag_destroy

=end

  def tag_destroy(current_user_id = nil)
    Tag.tag_destroy(
      object:        self.class.to_s,
      o_id:          id,
      created_by_id: current_user_id,
    )
    true
  end

end
