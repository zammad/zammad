# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Ticket::State < ApplicationModel
  belongs_to    :state_type,        :class_name => 'Ticket::StateType'
  validates     :name, :presence => true

  latest_change_support

=begin

list tickets by customer

  states = Ticket::State.by_category('open') # open|closed

returns:

  state objects

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

=begin

check if state is ignored for escalation

  state = Ticket::State.lookup( :name => 'state name' )

  result = state.ignore_escalation?

returns:

  true/false

=end

  def ignore_escalation?
    ignore_escalation = ['removed', 'closed', 'merged']
    return true if ignore_escalation.include?( self.name )
    return false
  end
end
