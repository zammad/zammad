# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
class Ticket::StateType < ApplicationModel
  include CanBeImported
  include ChecksLatestChangeObserved

  has_many :states, class_name: 'Ticket::State', inverse_of: :state_type

  validates :name, presence: true
end
