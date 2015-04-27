# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/
# rubocop:disable ClassAndModuleChildren
class Ticket::StateType < ApplicationModel
  has_many      :states,            class_name: 'Ticket::State'
  validates     :name, presence: true
  latest_change_support
end
