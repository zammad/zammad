# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Link::Object < ApplicationModel
  validates :name, presence: true
end
