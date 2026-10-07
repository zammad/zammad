# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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

  before_update :lock_ticket

  # Those callbacks are necessary to trigger updates in legacy UI.
  # First checklist item is created right after the checklist itself
  # and it triggers update on the freshly created ticket.
  # Thus no need for after_create callback.
  after_update :update_ticket
  after_update :report_checklist_existing_change

  before_destroy :lock_ticket, prepend: true

  after_destroy :update_ticket
  after_destroy :report_checklist_existing_change

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

  # The generic update endpoint takes this row through with_lock ahead of every callback, so the
  #   ticket row goes first here to keep the lock order of add_from_template!.
  def lock!(...)
    self.class.lock_ticket_of(id) if persisted?

    super
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
    ensure_template_active!(template)

    ActiveRecord::Base.transaction do
      # Refreshed behind the lock, so the ticket's check for an existing checklist judges the stored
      #   state rather than a copy another request has changed since.
      ticket.reload(lock: 'FOR NO KEY UPDATE')

      Checklist.create!(name: template.name, ticket:)
        .tap do |checklist|
          sorted_item_ids = template
            .sorted_items
            .map { |elem| checklist.items.create!(text: elem.text, initial_clone: true) }
            .pluck(:id)

          checklist.update! sorted_item_ids:
        end
    end
  end

  def self.add_from_template!(ticket, template)
    ensure_template_active!(template)

    # A savepoint, because the perform action rescues a failed write inside the job's slice
    #   transaction or the ticket's own one, which would otherwise commit the half-written checklist.
    ActiveRecord::Base.transaction(requires_new: true) do
      # Overlapping runs each hold their own copy of the ticket, so the stored state is read behind
      #   row locks: ticket first, as the macro and trigger flows already hold it on the way here and
      #   every manual checklist write takes it first too. FOR NO KEY UPDATE is what an UPDATE takes,
      #   so inserting an article or an item, which key-shares the ticket row, is not blocked by it.
      checklist_id = Ticket.where(id: ticket.id).lock('FOR NO KEY UPDATE').pick(:checklist_id)

      if checklist_id
        append_from_template!(Checklist.lock('FOR NO KEY UPDATE').find(checklist_id), template)
      else
        create_from_template!(ticket, template)
      end
    end
  end

  def self.lock_ticket_of(checklist_id)
    Ticket.where(checklist_id:).lock('FOR NO KEY UPDATE').pick(:id)
  end

  def self.append_from_template!(checklist, template)
    template_items = template.sorted_items.to_a

    # initial_clone skips the per-item limit validation, so the limit is checked before anything is written.
    if checklist.total + template_items.count > 100
      raise Exceptions::UnprocessableContent, __('Checklist items are limited to 100 items per checklist.')
    end

    new_item_ids = template_items.map { |elem| checklist.items.create!(text: elem.text, initial_clone: true).id.to_s }

    checklist.update! sorted_item_ids: checklist.sorted_item_ids + new_item_ids

    checklist
  end
  private_class_method :append_from_template!

  def self.ensure_template_active!(template)
    return if template.active

    raise Exceptions::UnprocessableContent, __('Checklist template must be active to use as a checklist starting point.')
  end
  private_class_method :ensure_template_active!

  private

  # Keeps the lock order of add_from_template!, ticket row first, as every write here ends in a ticket
  #   update. On destroy it is prepended to run ahead of the dependent items.
  def lock_ticket
    self.class.lock_ticket_of(id)
  end

  def update_ticket
    return if ticket.destroyed?

    ticket.updated_at = Time.current
    ticket.save!
  end

  # The selector answers "Has checklist" from the item rows, which no ticket column reflects, so a
  #   change of that answer is reported to the transaction dispatcher like a changed ticket attribute.
  def report_checklist_existing_change
    return if ticket.destroyed? || Setting.get('import_mode')

    before = (destroyed? ? sorted_item_ids : sorted_item_ids_before_last_save).present?
    after  = !destroyed? && sorted_item_ids.present?
    return if before == after

    EventBuffer.add('transaction', {
                      object:     'Ticket',
                      type:       'update',
                      changes:    { 'checklist_existing' => [before, after] },
                      id:         ticket.id,
                      user_id:    updated_by_id,
                      created_at: Time.zone.now,
                    })
  end
end
