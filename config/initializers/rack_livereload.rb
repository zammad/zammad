# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

if Rails.env.development? && ENV['RAKE_LIVE_RELOAD'].present?

  require 'rack-livereload'

  # strongly inspired by https://github.com/johnbintz/rack-livereload/issues/71#issuecomment-674899405
  module BodyProcessorExtension
    def process!(env)
      @content_security_policy_nonce = if ActionDispatch::Request.new(env).respond_to?(:content_security_policy_nonce)
                                         ActionDispatch::Request.new(env).content_security_policy_nonce
                                       end

      super
    end

    def template
      orignal_template = ::File.read(::File.expand_path('../../../../skel/livereload.html.erb', method(:template).super_method.source_location[0]))
      nonced_template  = orignal_template.gsub(%r{(<script type="text/javascript")}, '\1 nonce="<%= @content_security_policy_nonce %>"')

      ERB.new(nonced_template)
    end
  end

  Rack::LiveReload::BodyProcessor.prepend(BodyProcessorExtension)

  # Automatically inject JavaScript needed for LiveReload
  Rails.application.middleware.insert_after(
    ActionDispatch::Static,
    Rack::LiveReload,
    no_swf:           true,
    min_delay:        500,    # default 1000
    max_delay:        10_000, # default 60_000
    live_reload_port: 35_738
  )
end
