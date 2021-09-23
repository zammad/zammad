# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module ChecksCoreWorkflow
  extend ActiveSupport::Concern

  included do
    before_create :validate_workflows
    before_update :validate_workflows

    attr_accessor :screen
  end

  private

  def validate_workflows
    return if !screen
    return if !UserInfo.current_user_id

    perform_result = CoreWorkflow.perform(payload: {
                                            'event'      => 'core_workflow',
                                            'request_id' => 'ChecksCoreWorkflow.validate_workflows',
                                            'class_name' => self.class.to_s,
                                            'screen'     => screen,
                                            'params'     => attributes
                                          }, user: User.find(UserInfo.current_user_id))

    check_restrict_values(perform_result)
    check_visibility(perform_result)
    check_mandatory(perform_result)
  end

  def check_restrict_values(perform_result)
    changes.each_key do |key|
      next if perform_result[:restrict_values][key].blank?
      next if self[key].blank?
      next if restricted_value?(perform_result, key)

      raise Exceptions::UnprocessableEntity, "Invalid value '#{self[key]}' for field '#{key}'!"
    end
  end

  def restricted_value?(perform_result, key)
    perform_result[:restrict_values][key].any? { |value| value.to_s == self[key].to_s }
  end

  def check_visibility(perform_result)
    perform_result[:visibility].each_key do |key|
      next if perform_result[:visibility][key] != 'remove'

      self[key] = nil
    end
  end

  def check_mandatory(perform_result)
    perform_result[:mandatory].each_key do |key|
      next if field_visible?(perform_result, key)
      next if !field_mandatory?(perform_result, key)
      next if !column_value?(key)
      next if !colum_default?(key)

      raise Exceptions::UnprocessableEntity, "Missing required value for field '#{key}'!"
    end
  end

  def field_visible?(perform_result, key)
    %w[hide remove].include?(perform_result[:visibility][key])
  end

  def field_mandatory?(perform_result, key)
    perform_result[:mandatory][key]
  end

  def column_value?(key)
    self[key].nil?
  end

  def colum_default?(key)
    self.class.column_defaults[key].nil?
  end
end
