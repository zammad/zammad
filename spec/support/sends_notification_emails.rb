# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module SendsNotificationEmailsHelper

  # Provides a helper method to check notification email sending for a code block.
  #
  # @yield [] Description of block
  #
  # @example
  #   check_notification do
  #
  #     SomeClass.do_things_and_send_notification
  #
  #     sent(
  #       template: 'user_device_new',
  #       user:     admin,
  #     )
  #   end
  #
  # @return [nil]
  def check_notification
    @checking_notification = true
    reset_notification_checks
    yield
    @checking_notification = false
  end

  # Provides a helper method to check that a notification email wasn't sent.
  #
  # @param [Hash] args the arguments that get passed to "with hash_including" RSpec matchers
  #   @see NotificationFactory::Mailer.notification
  #
  # @example
  # not_sent(
  #   template: 'user_device_new_location',
  #   user:     admin,
  # )
  #
  # @return [nil]
  def not_sent(args)
    check_in_progress!
    expect(NotificationFactory::Mailer).to_not have_received(:notification).with(
      hash_including(args)
    )
  end

  # Provides a helper method to check that a notification email was sent.
  #
  # @param [Hash] args the arguments that get passed to "with hash_including" RSpec matchers
  #   @see NotificationFactory::Mailer.notification
  #
  # @example
  # sent(
  #   template: 'user_device_new_location',
  #   user:     admin,
  # )
  #
  # @return [nil]
  def sent(args)
    check_in_progress!
    expect(NotificationFactory::Mailer).to have_received(:notification).with(
      hash_including(args)
    ).once
  end

  private

  def reset_notification_checks
    check_in_progress!
    RSpec::Mocks.space.proxy_for(NotificationFactory::Mailer).reset
    # to be able to use `have_received` rspec expectations we need
    # to stub the class and allow all calls which starts "recording" calls
    allow(NotificationFactory::Mailer).to receive(:notification).and_call_original
  end

  def check_in_progress!
    return if @checking_notification

    raise "Don't check notification sending without `checking_notification` block around it."
  end
end

RSpec.configure do |config|
  config.include SendsNotificationEmailsHelper, sends_notification_emails: true
end
