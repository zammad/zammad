# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Ticket::State < ApplicationModel
  include CanBeImported
  include ChecksHtmlSanitized
  include ChecksLatestChangeObserved
  include HasCollectionUpdate
  include HasSearchIndexBackend

  belongs_to :state_type, class_name: 'Ticket::StateType', inverse_of: :states, optional: true
  belongs_to :next_state, class_name: 'Ticket::State', optional: true

  after_create  :ensure_defaults
  after_update  :ensure_defaults
  after_destroy :ensure_defaults

  validates :name, presence: true

  sanitized_html :note

  attr_accessor :callback_loop

=begin

looks up states for a given category

  states = Ticket::State.by_category(:open) # :open|:closed|:work_on|:work_on_all|:viewable|:viewable_agent_new|:viewable_agent_edit|:viewable_customer_new|:viewable_customer_edit|:pending_reminder|:pending_action|:pending|:merged

returns:

  state object list

=end

  def self.by_category(category)

    case category.to_sym
    when :open
      state_types = ['new', 'open', 'pending reminder', 'pending action']
    when :pending_reminder
      state_types = ['pending reminder']
    when :pending_action
      state_types = ['pending action']
    when :pending
      state_types = ['pending reminder', 'pending action']
    when :work_on
      state_types = %w[new open]
    when :work_on_all
      state_types = ['new', 'open', 'pending reminder']
    when :viewable
      state_types = ['new', 'open', 'pending reminder', 'pending action', 'closed', 'removed']
    when :viewable_agent_new
      state_types = ['new', 'open', 'pending reminder', 'pending action', 'closed']
    when :viewable_agent_edit
      state_types = ['open', 'pending reminder', 'pending action', 'closed']
    when :viewable_customer_new
      state_types = %w[new closed]
    when :viewable_customer_edit
      state_types = %w[open closed]
    when :closed
      state_types = %w[closed]
    when :merged
      state_types = %w[merged]
    end

    raise "Unknown category '#{category}'" if state_types.blank?

    Ticket::State.where(
      state_type_id: Ticket::StateType.where(name: state_types)
    )
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

    %w[default_create default_follow_up].each do |default_field|
      states_with_default = Ticket::State.where(default_field => true)
      next if states_with_default.count == 1

      if states_with_default.count.zero?
        state = Ticket::State.where(active: true).order(id: :asc).first
        state[default_field] = true
        state.callback_loop = true
        state.save!
        next
      end

      Ticket::State.all.each do |local_state|
        next if local_state.id == id
        next if local_state[default_field] == false

        local_state[default_field] = false
        local_state.callback_loop = true
        local_state.save!
        next
      end
    end
  end

end
