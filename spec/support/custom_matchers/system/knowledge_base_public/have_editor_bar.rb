# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module KnowledgeBasePublicMatchers
  module HaveEditorBar
    extend RSpec::Matchers::DSL

    matcher :have_editor_bar do
      match { actual.has_css? '.topbar' }
      description { 'display editor bar' }
      failure_message { 'expected to find editor bar above header, but did not' }
      failure_message_when_negated { 'expected not to find editor bar above header, but did' }
    end
  end
end

RSpec.configure do |config|
  config.include KnowledgeBasePublicMatchers::HaveEditorBar, type: :system
end
