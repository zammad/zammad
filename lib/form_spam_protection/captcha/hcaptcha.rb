# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# hCaptcha CAPTCHA provider.
class FormSpamProtection::Captcha::Hcaptcha < FormSpamProtection::Captcha
  include FormSpamProtection::Captcha::Concerns::TokenVerification

  def self.key
    'hcaptcha'
  end

  def self.title
    'hCaptcha'
  end

  private

  def provider_config
    {
      verify_url:     'https://api.hcaptcha.com/siteverify',
      script_url:     'https://js.hcaptcha.com/1/api.js',
      widget_class:   'h-captcha',
      response_field: 'h-captcha-response',
      global:         'hcaptcha',
    }
  end
end
