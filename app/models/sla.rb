# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Sla < ApplicationModel
  store      :condition
  store      :data
  validates  :name, presence: true
  belongs_to :calendar
end
