# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Modular spam protection for the web form channel. Combines an always-on
# honeypot check with an optionally configured CAPTCHA provider.
module FormSpamProtection
  # Bundles everything a check needs to evaluate a single form submission.
  Submission = Struct.new(:params, :request, keyword_init: true)

  # Public, secret-free configuration surfaced to the form widget via /form_config.
  #
  # @return [Hash]
  def self.frontend_config
    config = {}

    if Setting.get('form_ticket_create_honeypot')
      config[:honeypot] = { field: FormSpamProtection::Honeypot::FIELD_NAME }
    end

    if (captcha = FormSpamProtection::Captcha.configured_provider)
      config[:captcha] = captcha.frontend_config
    end

    config
  end

  # Stateless request checks (honeypot). Safe to run before field validation, as
  # they consume nothing.
  #
  # @param submission [Submission]
  #
  # @return [Boolean]
  def self.verify_request(submission)
    FormSpamProtection::Verifier.new(submission).request_valid?
  end

  # The configured single-use CAPTCHA challenge (true when none is configured).
  # Run only after field validation, so a field error does not consume a solved
  # challenge and break the next attempt.
  #
  # @param submission [Submission]
  #
  # @return [Boolean]
  def self.verify_challenge(submission)
    FormSpamProtection::Verifier.new(submission).challenge_valid?
  end
end
