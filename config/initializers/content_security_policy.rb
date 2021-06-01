# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

# Rails.application.config.content_security_policy do |policy|
#   policy.default_src :self, :https
#   policy.font_src    :self, :https, :data
#   policy.img_src     :self, :https, :data
#   policy.object_src  :none
#   policy.script_src  :self, :https
#   policy.style_src   :self, :https

#   # Specify URI for violation reports
#   # policy.report_uri "/csp-violation-report-endpoint"
# end

Rails.application.config.content_security_policy do |policy|
  base_uri = proc do
    next if !Rails.env.production?
    next if !Setting.get('system_init_done')

    http_type = Setting.get('http_type')
    fqdn      = Setting.get('fqdn')

    "#{http_type}://#{fqdn}"
  end

  policy.base_uri :self, base_uri

  policy.default_src :self, :ws, :wss, 'https://log.zammad.com', 'https://images.zammad.com'
  policy.font_src    :self, :data
  policy.img_src     '*', :data
  policy.object_src  :none
  policy.script_src  :self, :unsafe_eval, :unsafe_inline, :strict_dynamic
  policy.style_src   :self, :unsafe_inline
  policy.frame_src   'www.youtube.com', 'player.vimeo.com'
end

# If you are using UJS then enable automatic nonce generation
Rails.application.config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }

# Report CSP violations to a specified URI
# For further information see the following documentation:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
# Rails.application.config.content_security_policy_report_only = true
