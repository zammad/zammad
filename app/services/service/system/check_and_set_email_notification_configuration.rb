# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::System::CheckAndSetEmailNotificationConfiguration < Service::Base
  attr_reader :adapter, :new_configuration, :test_address

  # Check an Email Notification channel configuration with a test mail and save it once the server accepted that mail
  #
  # @param [String] adapter sendmail or smtp
  # @param [Hash] new_configuration email server configuration, see Service::System::SetEmailNotificationConfiguration
  # @param [String] test_address recipient of the test mail for a server which delivers to internal recipients only
  #
  # @return [Hash] result of EmailHelper::Probe.outbound, saved if its :result is 'ok'
  def initialize(adapter:, new_configuration:, test_address: nil)
    @adapter           = adapter
    @new_configuration = new_configuration
    @test_address      = test_address.to_s.strip.presence
  end

  def execute
    result = check

    save if result[:result] == 'ok'

    result
  end

  private

  def check
    return probe if !internal_only?
    return invalid_test_address if !EmailAddressValidation.new(test_address).valid?

    # Only a refusal of the usual check leads to the question for an internal-only server.
    probe(recipient: test_address).except(:refused)
  end

  # Sendmail hands the mail over without a reply of the server, so it has no internal-only route.
  def internal_only?
    test_address.present? && adapter.casecmp?('smtp')
  end

  # Without the BCC of the system, which a notification never carries: a server that only delivers to
  #   internal recipients would refuse the test mail for a BCC address outside the organization.
  def probe(**)
    EmailHelper::Probe.outbound(probe_configuration, Setting.get('notification_sender'), system_bcc: false, **)
  end

  # A copy, because the driver adds its defaults to the options it gets.
  def probe_configuration
    {
      adapter: adapter,
      options: new_configuration.to_h.deep_dup,
    }.with_indifferent_access
  end

  def invalid_test_address
    message = __('Please enter a valid email address.')

    {
      result:        'invalid',
      message:       message,
      message_human: message,
      invalid_field: { test_address: true },
    }
  end

  def save
    Service::System::SetEmailNotificationConfiguration.execute(
      adapter:,
      new_configuration:,
      internal_only:     internal_only?,
    )
  end
end
