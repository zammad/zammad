# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module KnowledgeBasePublicMatchers
  module ProduceSearchResultFor
    extend RSpec::Matchers::DSL

    matcher :produce_search_result_for do |expected|
      match do |actual|
        search_string = expected.translation.title

        actual.find('.js-search-input').fill_in with: search_string
        actual.find('.search-results').has_text? search_string
      end

      description do
        %(allows to search for "#{expected.translation.title}")
      end

      failure_message do
        %(could not search for "#{expected.translation.title}")
      end

      failure_message do
        %("#{expected.translation.title}" showed up in search results)
      end
    end
  end
end

RSpec.configure do |config|
  config.include KnowledgeBasePublicMatchers::ProduceSearchResultFor, type: :system
end
