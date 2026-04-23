# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::System::RunAutoWizard < Service::Base

  attr_reader :token

  def initialize(token:)
    @token = token
  end

  def execute
    raise Service::System::CheckSetup::SystemSetupError, __('This system has already been configured.') if Service::System::CheckSetup.done?
    raise AutoWizardNotEnabledError if !AutoWizard.enabled?

    auto_wizard_data = AutoWizard.data
    if auto_wizard_data.blank?
      raise AutoWizardExecutionError __('Invalid auto wizard file.')
    end

    if auto_wizard_data['Token'] && auto_wizard_data['Token'] != token
      raise AutoWizardExecutionError
    end

    AutoWizard.setup.tap do |admin_user|
      raise AutoWizardExecutionError __('Error during execution of auto wizard.') if !admin_user
    end
  end

  class AutoWizardNotEnabledError < StandardError; end
  class AutoWizardExecutionError < StandardError; end
end
