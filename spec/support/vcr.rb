# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

VCR_IGNORE_MATCHING_HOSTS = %w[elasticsearch selenium zammad.org zammad.com znuny.com google.com login.microsoftonline.com github.com].freeze
VCR_IGNORE_MATCHING_REGEXPS = [%r{^192\.168\.\d+\.\d+$}].freeze

VCR.configure do |config|
  config.cassette_library_dir = 'test/data/vcr_cassettes'
  config.hook_into :webmock
  config.allow_http_connections_when_no_cassette = false
  config.ignore_localhost = true
  config.ignore_request do |request|
    uri = URI(request.uri)

    next true if VCR_IGNORE_MATCHING_HOSTS.any?   { |elem| uri.host.include? elem }
    next true if VCR_IGNORE_MATCHING_REGEXPS.any? { |elem| uri.host.match? elem }
  end

  config.register_request_matcher(:oauth_headers) do |r1, r2|
    without_onetime_oauth_params = ->(params) { params.gsub(%r{oauth_(nonce|signature|timestamp)="[^"]+", }, '') }

    r1.headers.except('Authorization') == r2.headers.except('Authorization') &&
      r1.headers['Authorization']&.map(&without_onetime_oauth_params) ==
        r2.headers['Authorization']&.map(&without_onetime_oauth_params)
  end
end

module RSpec
  VCR_ADVISORY = <<~MSG.freeze
    If this test is failing unexpectedly, the VCR cassette may be to blame.
    This can happen when changing `describe`/`context` labels on some specs;
    see commit message 1ebddff95 for details.

    Check `git status` to see if a new VCR cassette has been generated.
    If so, rename the old cassette to replace the new one and try again.

  MSG

  module Support
    module VCRHelper
      def self.inject_advisory(example)
        # block argument is an #<RSpec::Expectations::ExpectationNotMetError>
        define_method(:notify_failure) do |e, options = {}|
          super(e.exception(VCR_ADVISORY + e.message), options)
        end

        example.run
      ensure
        remove_method(:notify_failure)
      end
    end

    singleton_class.send(:prepend, VCRHelper)
  end

  module Expectations
    module VCRHelper
      def self.inject_advisory(example)
        define_method(:handle_matcher) do |*args|
          super(*args)
        rescue => e
          raise e.exception(VCR_ADVISORY + e.message)
        end

        example.run
      ensure
        remove_method(:handle_matcher)
      end
    end

    PositiveExpectationHandler.singleton_class.send(:prepend, VCRHelper)
    NegativeExpectationHandler.singleton_class.send(:prepend, VCRHelper)
  end
end

RSpec.configure do |config|
  config.around(:each, use_vcr: true) do |example|
    vcr_options = Array(example.metadata[:use_vcr])

    spec_path       = Pathname.new(example.file_path).realpath
    cassette_path   = spec_path.relative_path_from(Rails.root.join('spec')).sub(%r{_spec\.rb$}, '')
    cassette_name   = "#{example.example_group.description} #{example.description}".gsub(%r{[^0-9A-Za-z.\-]+}, '_').downcase
    request_profile = [
      :method,
      :uri,
      vcr_options.include?(:with_oauth_headers) ? :oauth_headers : nil
    ].compact

    VCR.use_cassette(cassette_path.join(cassette_name), match_requests_on: request_profile) do |cassette|
      if vcr_options.include?(:time_sensitive) && !cassette.recording?
        travel_to(cassette.http_interactions.interactions.first.recorded_at)
      end

      example.run
    end
  end

  config.around(:each, use_vcr: true) do |example|
    RSpec::Support::VCRHelper.inject_advisory(example)
  end
  config.around(:each, use_vcr: true) do |example|
    RSpec::Expectations::VCRHelper.inject_advisory(example)
  end
end
