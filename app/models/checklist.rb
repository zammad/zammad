# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Checklist < ApplicationModel
  include HasDefaultModelUserRelations
  include ChecksClientNotification
  include HasHistory
  include Checklist::SearchIndex
  include Checklist::TriggersSubscriptions
  include Checklist::Assets
  include CanChecklistSortedItems

  has_one :ticket, dependent: :nullify
  has_many :items, inverse_of: :checklist, dependent: :destroy

  validates :name, length: { maximum: 250 }

  history_attributes_ignored :sorted_item_ids

  # Those callbacks are necessary to trigger updates in legacy UI.
  # First checklist item is created right after the checklist itself
  # and it triggers update on the freshly created ticket.
  # Thus no need for after_create callback.
  after_update :update_ticket
  after_destroy :update_ticket

  def history_log_attributes
    {
      related_o_id:           ticket.id,
      related_history_object: 'Ticket',
    }
  end

  def history_create
    history_log('created', created_by_id, { value_to: name })
  end

  def history_destroy
    history_log('removed', updated_by_id, { value_to: name })
  end

  def notify_clients_data_attributes
    {
      id:            id,
      ticket_id:     ticket.id,
      updated_at:    updated_at,
      updated_by_id: updated_by_id,
    }
  end

  def completed?
    incomplete.zero?
  end

  def incomplete
    items.incomplete.count
  end

  def total
    items.count
  end

  def complete
    total - incomplete
  end

  # Returns scope to tickets tracking the given target ticket in their checklists.
  # If a user is given, it returns tickets acccessible to that user only.
  #
  # @param target_ticket [Ticket, Integer] target ticket or it's id
  # @param user [User] to optionally filter accessible tickets
  def self.tickets_referencing(target_ticket, user = nil)
    source_checklist_ids = joins(:items)
      .where(items: { ticket: target_ticket })
      .pluck(:id)

    scope = Ticket.where(checklist_id: source_checklist_ids)

    return scope if !user

    TicketPolicy::ReadScope
      .new(user, scope)
      .resolve
  end

  def self.ticket_closed?(ticket)
    state      = Ticket::State.lookup id: ticket.state_id
    state_type = Ticket::StateType.lookup id: state.state_type_id

    %w[closed merged].include? state_type.name
  end

  def self.create_fresh!(ticket)
    ActiveRecord::Base.transaction do
      Checklist
        .create!(ticket:)
        .tap { |checklist| checklist.items.create! }
    end
  end

  def self.create_from_template!(ticket, template)
    if !template.active
      raise Exceptions::UnprocessableEntity, __('Checklist template must be active to use as a checklist starting point.')
    end

    ActiveRecord::Base.transaction do
      Checklist.create!(name: template.name, ticket:)
        .tap do |checklist|
          sorted_item_ids = template
            .items
            .map { |elem| checklist.items.create!(text: elem.text, initial_clone: true) }
            .pluck(:id)

          checklist.update! sorted_item_ids:
        end
    end
  end

  private

  def update_ticket
    return if ticket.destroyed?

    ticket.updated_at = Time.current
    ticket.save!
  end
end
