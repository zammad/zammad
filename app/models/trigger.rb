# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Trigger < ApplicationModel
  store     :condition
  store     :perform
  validates :name, presence: true
end
