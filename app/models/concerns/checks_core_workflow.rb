# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module ChecksCoreWorkflow
  extend ActiveSupport::Concern

  included do
    before_validation :validate_workflows

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

      value_found = perform_result[:restrict_values][key].any? { |value| value.to_s == self[key].to_s }
      next if value_found

      raise Exceptions::UnprocessableEntity, "Invalid value '#{self[key]}' for field '#{key}'!"
    end
  end

  def check_visibility(perform_result)
    perform_result[:visibility].each_key do |key|
      next if perform_result[:visibility][key] != 'remove'

      self[key] = nil
    end
  end

  def check_mandatory(perform_result)
    perform_result[:mandatory].each_key do |key|
      next if %w[hide remove].include?(perform_result[:visibility][key])
      next if !perform_result[:mandatory][key]
      next if self[key].present?

      raise Exceptions::UnprocessableEntity, "Missing required value for field '#{key}'!"
    end
  end
end
