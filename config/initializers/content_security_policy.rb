# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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

Rails.application.config.content_security_policy do |policy| # rubocop:disable Metrics/BlockLength
  base_uri = proc do
    next if !Rails.env.production?
    next if !Setting.get('system_init_done')

    http_type = Setting.get('http_type')
    fqdn      = Setting.get('fqdn')

    "#{http_type}://#{fqdn}"
  end

  policy.base_uri :self, base_uri

  # Allow embedding videos from the built-in providers (YouTube, Vimeo) and from
  # any self-hosted media server the admin has whitelisted. Evaluated per request
  # so newly whitelisted servers take effect without a restart. Returns the list
  # of origins; CSP wraps a proc's array result into individual frame-src sources.
  frame_src = proc do
    VideoEmbed.frame_src
  end

  policy.default_src     :self
  policy.connect_src     :self, :ws, :wss, 'https://images.zammad.com'
  policy.font_src        :self, :data
  policy.frame_ancestors :self
  policy.frame_src       frame_src
  policy.img_src         '*', :data, :blob
  policy.object_src      :none
  policy.script_src      :self, :unsafe_eval
  policy.style_src       :self, :unsafe_inline

  if Rails.env.development?
    websocket_uris = proc do
      # Match the websocket port the frontend actually uses (per-process ENV in dev,
      #   see SessionsController#config_frontend), falling back to the stored setting.
      websocket_port = ENV['ZAMMAD_WEBSOCKET_PORT'].presence || Setting.get('websocket_port')

      [
        "ws://#{ViteRuby.config.host_with_port}",
        "ws://#{ViteRuby.config.host}:#{websocket_port}",
        "ws://#{ViteRuby.config.host}:#{ENV['ZAMMAD_RAILS_PORT'] || 3000}/cable",

        # Include localhost URIs as well, to cover local setups where ViteRuby is configured to use another hostname.
        *(if ViteRuby.config.host != 'localhost'
            [
              "ws://localhost:#{ViteRuby.config.port}",
              "ws://localhost:#{websocket_port}",
              "ws://localhost:#{ENV['ZAMMAD_RAILS_PORT'] || 3000}/cable",
            ]
          end)
      ].compact
    end

    policy.script_src :self, :unsafe_eval, :unsafe_inline
    policy.connect_src :self, :https, :wss, "http://#{ViteRuby.config.host_with_port}", *websocket_uris
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
