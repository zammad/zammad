# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sla < ApplicationModel
  include ChecksClientNotification
  include ChecksConditionValidation
  include HasEscalationCalculationImpact
  include Sla::Assets

  belongs_to :calendar, optional: true

  # workflow checks should run after before_create and before_update callbacks
  include ChecksCoreWorkflow

  validates  :name, presence: true

  validate   :cannot_have_response_and_update

  store      :condition
  store      :data

  def condition_matches?(ticket)
    query_condition, bind_condition, tables = Ticket.selector2sql(condition)
    Ticket.where(query_condition, *bind_condition).joins(tables).exists?(ticket.id)
  end

  def self.for_ticket(ticket)
    fallback = nil
    all.order(:name, :created_at).as_batches(size: 10) do |record|
      if record.condition.present?
        return record if record.condition_matches?(ticket)
      else
        fallback = record
      end
    end
    fallback
  end

  private

  def cannot_have_response_and_update
    return if response_time.blank? || update_time.blank?

    errors.add :base, 'cannot have both response time and update time'
  end
end
