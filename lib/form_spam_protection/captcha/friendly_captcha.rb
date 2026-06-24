# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Friendly Captcha provider — a proof-of-work widget that is GDPR-friendly and
# EU-hosted. Currently integrates the `friendly-challenge` widget; the newer
# @friendlycaptcha/sdk widget is a drop-in successor under the same provider.
class FormSpamProtection::Captcha::FriendlyCaptcha < FormSpamProtection::Captcha
  include FormSpamProtection::Captcha::Concerns::TokenVerification

  def self.key
    'friendly_captcha'
  end

  def self.title
    __('Friendly Captcha')
  end

  private

  def provider_config
    {
      verify_url:      'https://api.friendlycaptcha.com/api/v1/siteverify',
      script_url:      'https://cdn.jsdelivr.net/npm/friendly-challenge@0.9.20/widget.min.js',
      widget_class:    'frc-captcha',
      response_field:  'frc-captcha-solution',
      global:          'friendlyChallenge',
      # The friendly-challenge widget has no render() and only auto-scans once; late
      # widgets are initialized in the form widget via `new friendlyChallenge.WidgetInstance(...)`.
      widget_instance: true,
    }
  end

  # Friendly Captcha's siteverify expects `solution` and `sitekey` instead of
  # the `response`/`remoteip` shape used by the other providers.
  def siteverify_params(response, _request)
    {
      solution: response,
      secret:   secret,
      sitekey:  site_key,
    }
  end
end
