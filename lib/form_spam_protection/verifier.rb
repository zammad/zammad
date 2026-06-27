# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Runs the spam-protection checks for a single form submission. The checks are
# split into stateless request checks (honeypot) and the single-use CAPTCHA
# challenge, so the controller can run the challenge only after field validation
# has passed (otherwise a field error would consume a solved token).
class FormSpamProtection::Verifier
  def initialize(submission)
    @submission = submission
  end

  # @return [Boolean] true when all enabled stateless request checks pass.
  def request_valid?
    request_checks.all? { |check| check.verify(@submission) }
  end

  # @return [Boolean] true when the configured CAPTCHA passes, or none is configured.
  def challenge_valid?
    provider = FormSpamProtection::Captcha.configured_provider
    return true if provider.nil?

    provider.verify(@submission)
  end

  private

  def request_checks
    checks = []
    checks << FormSpamProtection::Honeypot.new if Setting.get('form_ticket_create_honeypot')
    checks
  end
end
