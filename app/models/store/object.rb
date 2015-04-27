# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Store::Object < ApplicationModel
  validates :name, presence: true
end