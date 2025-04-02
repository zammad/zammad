# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Ticket::TimeAccounting < ApplicationModel
  validates :time_unit, presence: true

  belongs_to :type, class_name: 'Ticket::TimeAccounting::Type', optional: true
  belongs_to :ticket
  belongs_to :ticket_article, class_name: 'Ticket::Article', inverse_of: :ticket_time_accounting, optional: true

  after_destroy :update_time_units
  after_save    :update_time_units

  # This is a model-only constraint.
  # When this was introduced, there was no check for uniqueness of ticket_article_id for a long time.
  # It would be very difficult to safely migrate existing systems.
  # If somebody has added time accounting entry for the same article twice, we can't neither remove it nor move elsewhere it safely.
  # This may throw a rubocop warning locally. But it does nothing in CI because db/schema.rb doesn't exist and cop is skipped.
  validates :ticket_article_id, uniqueness: { allow_nil: true } # rubocop:disable Rails/UniqueValidationWithoutIndex, Lint/RedundantCopDisableDirective

  validate :verify_ticket_article, on: :create

  def self.update_ticket(ticket)
    time_units = total(ticket)
    return if ticket.time_unit.to_d == time_units

    ticket.time_unit = time_units
    ticket.save!
  end

  def self.total(ticket)
    ticket.ticket_time_accounting.sum(:time_unit)
  end
  private_class_method :total

  private

  def update_time_units
    self.class.update_ticket(ticket)
  end

  def verify_ticket_article
    return if ticket_article.blank?
    return if ticket_article.ticket_id == ticket_id

    errors.add :ticket_article, __('This article is not part of the ticket.')
  end
end
