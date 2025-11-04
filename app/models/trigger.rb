# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Trigger < ApplicationModel
  include ChecksConditionValidation
  include ChecksHtmlSanitized
  include CanSeed
  include HasSearchIndexBackend
  include CanSelector
  include CanSearch
  include ChecksClientNotification
  include TouchesPerformReferences

  include Trigger::Assets

  store     :condition
  store     :perform
  validates :name,    presence: true, uniqueness: { case_sensitive: false }
  validates :perform, 'validations/verify_perform_rules': true

  validates :activator, presence: true, inclusion: { in: %w[action time] }
  validates :execution_condition_mode, presence: true, inclusion: { in: %w[selective always] }

  validates :note, length: { maximum: 250 }

  sanitized_html :note

  scope :activated_by, ->(activator) { where(active: true, activator: activator) }

  def performed_on(object, activator_type:)
    return if !time_based?

    history_scope(object, activator_type:).create sourceable_name: name
  end

  def performable_on?(object, activator_type:)
    return if !time_based?

    already_notified_cutoff = Time.use_zone(Setting.get('timezone_default')) { Time.current.beginning_of_day }

    !history_scope(object, activator_type:).exists?(['created_at > ?', already_notified_cutoff])
  end

  def condition_changes_required?
    activator == 'action' && execution_condition_mode == 'selective'
  end

  private

  def time_based?
    activator == 'time'
  end

  def history_scope(object, activator_type:)
    History
      .where(
        history_object_id: History.object_lookup(object.class.name).id,
        o_id:              object.id,
        history_type_id:   History.type_lookup('time_trigger_performed').id,
        sourceable:        self,
        value_from:        activator_type
      )
  end
end
