# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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
# Allow @vite/client to hot reload changes in development
#    policy.script_src *policy.script_src, :unsafe_eval, "http://#{ ViteRuby.config.host_with_port }" if Rails.env.development?

# You may need to enable this in production as well depending on your setup.
#    policy.script_src *policy.script_src, :blob if Rails.env.test?

#   policy.style_src   :self, :https
#   # If you are using webpack-dev-server then specify webpack-dev-server host
#   policy.connect_src :self, :https, "http://localhost:3035", "ws://localhost:3035" if Rails.env.development?
# Allow @vite/client to hot reload changes in development
#    policy.connect_src *policy.connect_src, "ws://#{ ViteRuby.config.host_with_port }" if Rails.env.development?

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

  policy.default_src :self, :ws, :wss, 'https://images.zammad.com'
  policy.font_src    :self, :data
  policy.img_src     '*', :data
  policy.object_src  :none
  policy.script_src  :self, :unsafe_eval
  policy.style_src   :self, :unsafe_inline
  policy.frame_src   'www.youtube.com', 'player.vimeo.com'

  if Rails.env.development?
    websocket_uri = proc do
      "ws://#{ViteRuby.config.host}:#{Setting.get('websocket_port')}"
    end

    websocket_cable_uri = proc do
      "ws://#{ViteRuby.config.host}:#{ENV['ZAMMAD_RAILS_PORT'] || 3000}/cable"
    end

    policy.script_src :self, :unsafe_eval, :unsafe_inline
    policy.connect_src :self, :https, :wss, "http://#{ViteRuby.config.host_with_port}", "ws://#{ViteRuby.config.host_with_port}", websocket_cable_uri, websocket_uri
  end
end

# If you are using UJS then enable automatic nonce generation
Rails.application.config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }

# Set the nonce only to specific directives
Rails.application.config.content_security_policy_nonce_directives = %w[script-src]

# Report CSP violations to a specified URI
# For further information see the following documentation:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
Rails.application.config.content_security_policy_report_only = true if Rails.env.development?
