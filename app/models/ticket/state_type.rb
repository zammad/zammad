# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
class Ticket::StateType < ApplicationModel
  include ChecksLatestChangeObserved

  has_many  :states, class_name: 'Ticket::State'
  validates :name, presence: true
end
