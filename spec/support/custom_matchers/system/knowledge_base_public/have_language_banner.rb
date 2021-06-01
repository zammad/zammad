# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module KnowledgeBasePublicMatchers
  module HaveLanguageBanner
    extend RSpec::Matchers::DSL

    matcher :have_language_banner do
      match { actual.has_css? '.language-banner' }
      description { 'display language banner' }
      failure_message { 'expected to find language banner, but did not' }
      failure_message_when_negated { 'expected not to find language banner, but did' }
    end
  end
end

RSpec.configure do |config|
  config.include KnowledgeBasePublicMatchers::HaveLanguageBanner, type: :system
end
