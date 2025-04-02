# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Sla < ApplicationModel
  include ChecksClientNotification
  include ChecksConditionValidation
  include HasEscalationCalculationImpact
  include Sla::Assets

  belongs_to :calendar, optional: true

  # workflow checks should run after before_create and before_update callbacks
  include ChecksCoreWorkflow

  core_workflow_screens 'create', 'edit'

  validates  :name, presence: true, uniqueness: { case_sensitive: false }

  validate   :cannot_have_response_and_update

  store      :condition
  store      :data

  def condition_matches?(ticket)
    query_condition, bind_condition, tables = Ticket.selector2sql(condition)
    Ticket.where(query_condition, *bind_condition).joins(tables).exists?(ticket.id)
  end

  def self.for_ticket(ticket)
    fallback = nil
    all.reorder(:name, :created_at).as_batches(size: 10) do |record|
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

    errors.add :base, __('Cannot have both response time and update time.')
  end
end
