# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sla < ApplicationModel
  include ChecksClientNotification
  include ChecksConditionValidation
  include HasEscalationCalculationImpact
  include Sla::Assets

  belongs_to :calendar, optional: true

  # workflow checks should run after before_create and before_update callbacks
  include ChecksCoreWorkflow

  validates  :name, presence: true

  store      :condition
  store      :data

  def condition_matches?(ticket)
    query_condition, bind_condition, tables = Ticket.selector2sql(condition)
    Ticket.where(query_condition, *bind_condition).joins(tables).exists?(ticket.id)
  end

  def self.for_ticket(ticket)
    fallback = nil
    all.order(:name, :created_at).find_each do |record|
      if record.condition.present?
        return record if record.condition_matches?(ticket)
      else
        fallback = record
      end
    end
    fallback
  end
end
