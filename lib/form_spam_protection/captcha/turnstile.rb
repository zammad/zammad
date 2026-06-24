# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Cloudflare Turnstile CAPTCHA provider.
class FormSpamProtection::Captcha::Turnstile < FormSpamProtection::Captcha
  include FormSpamProtection::Captcha::Concerns::TokenVerification

  def self.key
    'turnstile'
  end

  def self.title
    __('Cloudflare Turnstile')
  end

  private

  def provider_config
    {
      verify_url:     'https://challenges.cloudflare.com/turnstile/v0/siteverify',
      script_url:     'https://challenges.cloudflare.com/turnstile/v0/api.js',
      widget_class:   'cf-turnstile',
      response_field: 'cf-turnstile-response',
      global:         'turnstile',
    }
  end
end
