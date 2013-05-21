class Ticket::State < ApplicationModel
  belongs_to    :state_type,        :class_name => 'Ticket::StateType'
  validates     :name, :presence => true
end