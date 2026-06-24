# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Google reCAPTCHA v3 provider. Invisible and score-based: the widget runs no
# challenge, a token is fetched on submit, and the siteverify response is
# accepted only when its risk score meets the configured minimum.
#
# reCAPTCHA Enterprise (different credentials + assessment API) is intended as a
# separate provider sharing the same invisible "score" frontend.
class FormSpamProtection::Captcha::Recaptcha < FormSpamProtection::Captcha
  include FormSpamProtection::Captcha::Concerns::TokenVerification

  DEFAULT_MIN_SCORE = 0.5

  def self.key
    'recaptcha'
  end

  def self.title
    __('Google reCAPTCHA')
  end

  private

  def provider_config
    {
      type:           'score',
      verify_url:     'https://www.google.com/recaptcha/api/siteverify',
      script_url:     "https://www.google.com/recaptcha/api.js?render=#{site_key}",
      response_field: 'g-recaptcha-response',
      global:         'grecaptcha',
      action:         'submit',
    }
  end

  def accepted?(data)
    super && data['score'].to_f >= min_score
  end

  def min_score
    options[:min_score].presence&.to_f || DEFAULT_MIN_SCORE
  end
end
