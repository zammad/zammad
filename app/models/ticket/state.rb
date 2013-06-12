# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

class Ticket::State < ApplicationModel
  belongs_to    :state_type,        :class_name => 'Ticket::StateType'
  validates     :name, :presence => true
end
