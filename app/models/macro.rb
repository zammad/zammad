# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Macro < ApplicationModel
  include ChecksClientNotification
  include ChecksHtmlSanitized
  include CanSeed
  include HasCollectionUpdate
  include HasSearchIndexBackend
  include CanSelector
  include CanSearch
  include Macro::TriggersSubscriptions

  store     :perform
  validates :perform,         'validations/verify_perform_rules': true
  validates :name,            presence: true, uniqueness: { case_sensitive: false }
  validates :ux_flow_next_up, inclusion: { in: %w[none next_task next_task_on_close next_from_overview] }

  has_and_belongs_to_many :groups, after_add: :cache_update, after_remove: :cache_update, class_name: 'Group'

  validates :note, length: { maximum: 250 }
  sanitized_html :note

  collection_push_permission('ticket.agent')

  scope :available_in_groups, lambda { |groups|
    left_outer_joins(:groups_macros)
    .where(groups_macros: { group_id: [nil] + Array(groups) })
    .where(active: true)
    .distinct
  }

  ApplicableOn = Struct.new(:result, :blocking_tickets) do
    delegate :==, to: :result
    delegate :!, to: :result

    def error_message
      "Macro blocked by: #{blocking_tickets.join(', ')}"
    end
  end

  def applicable_on?(tickets)
    tickets = Array(tickets)

    return ApplicableOn.new(true, []) if group_ids.blank?

    blocking = tickets.reject { |elem| group_ids.include? elem.group_id }

    ApplicableOn.new(blocking.none?, blocking)
  end

  def performable_on?(object, activator_type:)
    return false if !active
    return true if group_ids.blank?

    group_ids.include? object.group_id
  end
end
