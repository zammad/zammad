# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Store
  class Object < ApplicationModel
    validates :name, presence: true
  end
end
