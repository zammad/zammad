# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Tag::Object < ApplicationModel
  validates :name, presence: true

=begin

lookup by name and create tag item

  tag_object = Tag::Object.lookup_by_name_and_create('some tag')

=end

  def self.lookup_by_name_and_create(name)
    name.strip!

    tag_object = Tag::Object.lookup(name: name)
    return tag_object if tag_object

    Tag::Object.create(name: name)
  end
end
