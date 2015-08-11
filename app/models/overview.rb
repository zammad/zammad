# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Overview < ApplicationModel
  store     :condition
  store     :order
  store     :view
  validates :name, presence: true
  validates :prio, presence: true
  validates :link, presence: true
end
