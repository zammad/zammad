# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

class Ticket::State < ApplicationModel
  belongs_to    :state_type,        :class_name => 'Ticket::StateType'
  validates     :name, :presence => true

=begin

list tickets by customer

  states = Ticket::State.by_category('open') # open|closed

=end

  def self.by_category(category)
    if category == 'open'
      return Ticket::State.where(
        :state_type_id => Ticket::StateType.where( :name => ['new', 'open', 'pending reminder', 'pending action'] )
      )
    elsif category == 'closed'
  	  return Ticket::State.where(
        :state_type_id => Ticket::StateType.where( :name => ['closed'] )
      )
  	end
    raise "Unknown category '#{category}'"
  end
end
