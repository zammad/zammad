# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Google reCAPTCHA Enterprise provider. Shares the invisible, score-based
# frontend with reCAPTCHA v3, but verifies via the Enterprise Assessment API
# (a Cloud project ID + API key) instead of the classic siteverify endpoint.
#
# @see https://cloud.google.com/recaptcha/docs/create-assessment
class FormSpamProtection::Captcha::RecaptchaEnterprise < FormSpamProtection::Captcha
  DEFAULT_MIN_SCORE = 0.5
  ACTION            = 'submit'.freeze
  RESPONSE_FIELD    = 'g-recaptcha-response'.freeze

  def self.key
    'recaptcha_enterprise'
  end

  def self.title
    __('Google reCAPTCHA Enterprise')
  end

  def verify(submission)
    token = submission.params[RESPONSE_FIELD]
    if token.blank?
      Rails.logger.debug { "Form spam protection: rejected submission (missing #{self.class.key} response)." }
      return false
    end

    if api_key.blank? || project_id.blank?
      Rails.logger.error "Form spam protection: #{self.class.key} is selected but project ID or API key is not configured."
      return false
    end

    data = assess(token)
    return false if data.nil?

    return true if accepted?(data)

    Rails.logger.debug { "Form spam protection: rejected submission (#{self.class.key} verification failed)." }
    false
  end

  private

  def widget_config
    {
      type:           'score',
      script_url:     "https://www.google.com/recaptcha/enterprise.js?render=#{site_key}",
      response_field: RESPONSE_FIELD,
      global:         'grecaptcha.enterprise',
      site_key:       site_key,
      action:         ACTION,
    }
  end

  # @return [Hash, nil] the parsed assessment, or nil on a transport failure.
  def assess(token)
    url    = "https://recaptchaenterprise.googleapis.com/v1/projects/#{CGI.escape(project_id.to_s)}/assessments"
    params = { event: { token:, siteKey: site_key, expectedAction: ACTION } }

    # Pass the API key via header instead of the URL query string, so it doesn't
    # end up in proxy/access logs.
    result = UserAgent.post(url, params, { verify_ssl: true, json: true, headers: { 'X-Goog-Api-Key' => api_key } })

    if !result.success?
      Rails.logger.error "Form spam protection: #{self.class.key} request failed (HTTP #{result.code})."
      return nil
    end

    result.data
  rescue => e
    Rails.logger.error "Form spam protection: #{self.class.key} verification error (#{e.message})."
    nil
  end

  def accepted?(data)
    data.dig('tokenProperties', 'valid') == true && data.dig('riskAnalysis', 'score').to_f >= min_score
  end

  def project_id
    options[:project_id]
  end

  def api_key
    options[:api_key]
  end

  def min_score
    options[:min_score].presence&.to_f || DEFAULT_MIN_SCORE
  end
end
