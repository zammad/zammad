class Ticket::StateType < ApplicationModel
  has_many      :states,            :class_name => 'Ticket::State'
  validates     :name, :presence => true
end