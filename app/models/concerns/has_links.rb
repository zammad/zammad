# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module HasLinks
  extend ActiveSupport::Concern

  included do
    before_destroy :links_destroy
  end

=begin

delete object link list, will be executed automatically

  model = Model.find(123)
  model.links_destroy

=end

  def links_destroy
    Link.remove_all(
      link_object:       self.class.to_s,
      link_object_value: id,
    )
    true
  end
end
