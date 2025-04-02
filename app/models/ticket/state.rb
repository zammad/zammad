# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Ticket::State < ApplicationModel
  include HasDefaultModelUserRelations

  include CanBeImported
  include ChecksHtmlSanitized
  include HasCollectionUpdate
  include HasSearchIndexBackend

  belongs_to :state_type, class_name: 'Ticket::StateType', inverse_of: :states, optional: true
  belongs_to :next_state, class_name: 'Ticket::State', optional: true

  after_create  :ensure_defaults
  before_update :prevent_merged_state_editing
  after_update  :ensure_defaults
  before_destroy :prevent_merged_state_destruction
  after_destroy :ensure_defaults

  after_destroy :update_object_manager_attribute
  after_save :update_object_manager_attribute

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  validates :note, length: { maximum: 250 }
  sanitized_html :note

  validates :state_type_id, uniqueness: { if: :state_type_solo? }

  attr_accessor :callback_loop

  default_scope { order(id: :asc) }

=begin

looks up states for a given category

  states = Ticket::State.by_category(:open) # :open|:closed|:work_on|:work_on_all|:viewable|:viewable_agent_new|:viewable_agent_edit|:viewable_customer_new|:viewable_customer_edit|:pending_reminder|:pending_action|:pending|:merged

returns:

  state object list

=end

  scope :by_category, lambda { |category|
    joins(:state_type)
      .where(ticket_state_types: { name: Ticket::StateType.names_in_category(category) })
  }

  scope :active, -> { where(active: true) }

  def self.by_category_ids(category)
    by_category(category).pluck(:id)
  end

  def ensure_defaults
    return if callback_loop

    %w[default_create default_follow_up].each do |default_field|
      states_with_default = Ticket::State.where(default_field => true)
      next if states_with_default.count == 1

      if states_with_default.count.zero?
        state = Ticket::State.where(active: true).reorder(id: :asc).first
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

  def self.update_state_field_configuration
    attr = ObjectManager::Attribute.get(
      object: 'Ticket',
      name:   'state_id',
    )

    active_states = Ticket::State.where(active: true)

    attr.data_option[:filter]                                = active_states.by_category_ids(:viewable)
    attr.screens[:create_middle]['ticket.agent'][:filter]    = active_states.by_category_ids(:viewable_agent_new)
    attr.screens[:create_middle]['ticket.customer'][:filter] = active_states.by_category_ids(:viewable_customer_new)
    attr.screens[:edit]['ticket.agent'][:filter]             = active_states.by_category_ids(:viewable_agent_edit)
    attr.screens[:edit]['ticket.customer'][:filter]          = active_states.by_category_ids(:viewable_customer_edit)
    attr.screens[:overview_bulk]['ticket.agent'][:filter]    = active_states.by_category_ids(:viewable_agent_edit)

    attr.save!
  end

  # Allow to lookup state by state type ID
  def self.lookup_keys
    @lookup_keys ||= super + [:state_type_id]
  end

  private

  def update_object_manager_attribute
    return if !Setting.get('system_init_done')
    return if callback_loop

    self.class.update_state_field_configuration
  end

  def state_type_solo?
    # OTRS import creates a copy of all states, including merged, and that's OK
    return false if Setting.get('import_mode')

    state_type&.solo?
  end

  def prevent_merged_state_editing
    # OTRS import creates a copy of all states, including merged, and that's OK
    return if Setting.get('import_mode')

    return if state_type.name != 'merged'

    throw :abort
  end

  def prevent_merged_state_destruction
    # OTRS import creates a copy of all states, including merged, and that's OK
    return if Setting.get('import_mode')

    return if state_type.name != 'merged'

    throw :abort
  end
end
