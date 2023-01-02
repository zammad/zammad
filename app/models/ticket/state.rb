# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Ticket::State < ApplicationModel
  include CanBeImported
  include ChecksHtmlSanitized
  include HasCollectionUpdate
  include HasSearchIndexBackend

  belongs_to :state_type, class_name: 'Ticket::StateType', inverse_of: :states, optional: true
  belongs_to :next_state, class_name: 'Ticket::State', optional: true

  after_create  :ensure_defaults
  after_update  :ensure_defaults
  after_destroy :ensure_defaults

  validates :name, presence: true

  validates :note, length: { maximum: 250 }
  sanitized_html :note

  attr_accessor :callback_loop

  TYPES = {
    open:                   ['new', 'open', 'pending reminder', 'pending action'],
    pending_reminder:       ['pending reminder'],
    pending_action:         ['pending action'],
    pending:                ['pending reminder', 'pending action'],
    work_on:                %w[new open],
    work_on_all:            ['new', 'open', 'pending reminder'],
    viewable:               ['new', 'open', 'pending reminder', 'pending action', 'closed', 'removed'],
    viewable_agent_new:     ['new', 'open', 'pending reminder', 'pending action', 'closed'],
    viewable_agent_edit:    ['open', 'pending reminder', 'pending action', 'closed'],
    viewable_customer_new:  %w[new closed],
    viewable_customer_edit: %w[open closed],
    closed:                 %w[closed],
    merged:                 %w[merged],
  }.freeze

=begin

looks up states for a given category

  states = Ticket::State.by_category(:open) # :open|:closed|:work_on|:work_on_all|:viewable|:viewable_agent_new|:viewable_agent_edit|:viewable_customer_new|:viewable_customer_edit|:pending_reminder|:pending_action|:pending|:merged

returns:

  state object list

=end

  def self.by_category(*categories)
    state_types = TYPES.slice(*categories.map(&:to_sym)).values.uniq
    raise ArgumentError, "No such categories (#{categories.join(', ')})" if state_types.empty?

    Ticket::State.joins(:state_type).where(ticket_state_types: { name: state_types })
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
