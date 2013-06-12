# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

class Ticket::StateType < ApplicationModel
  has_many      :states,            :class_name => 'Ticket::State'
  validates     :name, :presence => true
end
