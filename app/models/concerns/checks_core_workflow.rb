# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module ChecksCoreWorkflow
  extend ActiveSupport::Concern

  included do
    before_create :validate_workflows
    before_update :validate_workflows

    attr_accessor :screen
  end

  private

  class_methods do

    # defines the screens which core workflow executes
    def core_workflow_screens(*screens)
      @core_workflow_screens ||= screens
    end

    # defines the screens which are configurable via admin interface
    def core_workflow_admin_screens(*screens)
      @core_workflow_admin_screens ||= screens
    end
  end

  def validate_workflows
    return if !screen
    return if !UserInfo.current_user_id

    perform_result = CoreWorkflow.perform(payload: {
                                            'event'      => 'core_workflow',
                                            'request_id' => 'ChecksCoreWorkflow.validate_workflows',
                                            'class_name' => self.class.to_s,
                                            'screen'     => screen,
                                            'params'     => attributes
                                          }, user: User.find(UserInfo.current_user_id), assets: false)

    check_restrict_values(perform_result)
    check_mandatory(perform_result)
  end

  def check_restrict_values(perform_result)
    merged_restrict_values = merge_changes_into_restrict_values(perform_result[:restrict_values], changes)
    changes.each_key do |key|
      Rails.logger.warn "SWIFT_KEV Restricted Values Key :::: #{merged_restrict_values}"
      Rails.logger.warn "SWIFT_KEV perform_result Key :::: #{perform_result}"

      # Check if merged_restrict_values is not nil and key is present
      next if merged_restrict_values&.[](key)&.any? { |value| value.to_s == self[key].to_s }
      next if self[key].blank?
      next if restricted_value?(perform_result, key)

      raise Exceptions::ApplicationModel.new(self, "Invalid value '#{self[key]}' for field '#{key}'!")
    end
  end

  def merge_changes_into_restrict_values(restrict_values, changes)
    return restrict_values if !(restrict_values.is_a?(Hash) && changes.is_a?(Hash))

    # Iterate through changes and merge each value into the corresponding key in restrict_values
    changes.each do |key, value|
      restrict_values[key] ||= []
      restrict_values[key] |= Array(value).map(&:to_s)
    end

    restrict_values
  end

  def restricted_value?(perform_result, key)
    if self[key].is_a?(Array)
      (self[key].map(&:to_s) - perform_result[:restrict_values][key].map(&:to_s)).blank?
    else
      perform_result[:restrict_values][key].any? { |value| value.to_s == self[key].to_s }
    end
  end

  def check_mandatory(perform_result)
    perform_result[:mandatory].each_key do |key|
      next if field_visible?(perform_result, key)
      next if !field_mandatory?(perform_result, key)
      next if !column_empty?(key)
      next if !colum_default?(key)

      raise Exceptions::ApplicationModel.new(self, "Missing required value for field '#{key}'!")
    end
  end

  def field_visible?(perform_result, key)
    %w[hide remove].include?(perform_result[:visibility][key])
  end

  def field_mandatory?(perform_result, key)
    perform_result[:mandatory][key]
  end

  def column_empty?(key)
    self[key].nil? || ([true, false].exclude?(self[key]) && self[key].blank?)
  end

  def colum_default?(key)
    self.class.column_defaults[key].nil?
  end
end
