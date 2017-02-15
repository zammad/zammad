# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
class Ticket::State < ApplicationModel
  include LatestChangeObserved

  after_create  :ensure_defaults
  after_update  :ensure_defaults
  after_destroy :ensure_defaults

  belongs_to    :state_type, class_name: 'Ticket::StateType'
  belongs_to    :next_state, class_name: 'Ticket::State'
  validates     :name, presence: true

  attr_accessor :callback_loop

=begin

list tickets by customer

  states = Ticket::State.by_category('open') # open|closed|work_on|work_on_all|pending_reminder|pending_action|merged

returns:

  state objects

=end

  def self.by_category(category)
    if category == 'open'
      return Ticket::State.where(
        state_type_id: Ticket::StateType.where(name: ['new', 'open', 'pending reminder', 'pending action'])
      )
    elsif category == 'pending_reminder'
      return Ticket::State.where(
        state_type_id: Ticket::StateType.where(name: ['pending reminder'])
      )
    elsif category == 'pending_action'
      return Ticket::State.where(
        state_type_id: Ticket::StateType.where(name: ['pending action'])
      )
    elsif category == 'work_on'
      return Ticket::State.where(
        state_type_id: Ticket::StateType.where(name: %w(new open))
      )
    elsif category == 'work_on_all'
      return Ticket::State.where(
        state_type_id: Ticket::StateType.where(name: ['new', 'open', 'pending reminder'])
      )
    elsif category == 'closed'
      return Ticket::State.where(
        state_type_id: Ticket::StateType.where(name: %w(closed))
      )
    elsif category == 'merged'
      return Ticket::State.where(
        state_type_id: Ticket::StateType.where(name: %w(merged))
      )
    end
    raise "Unknown category '#{category}'"
  end

=begin

check if state is ignored for escalation

  state = Ticket::State.lookup(name: 'state name')

  result = state.ignore_escalation?

returns:

  true/false

=end

  def ignore_escalation?
    return true if ignore_escalation
    false
  end

  def ensure_defaults
    return if callback_loop

    %w(default_create default_follow_up).each do |default_field|
      states_with_default = Ticket::State.where(default_field => true)
      next if states_with_default.count == 1

      if states_with_default.count.zero?
        state = Ticket::State.where(active: true).order(id: :asc).first
        state[default_field] = true
        state.callback_loop = true
        state.save!
        next
      end

      Ticket::State.all.each { |local_state|
        next if local_state.id == id
        next if local_state[default_field] == false
        local_state[default_field] = false
        local_state.callback_loop = true
        local_state.save!
        next
      }
    end
  end

end
