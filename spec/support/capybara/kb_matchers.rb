RSpec::Matchers.define :allow_to_search_for do |expected|
  match do |actual|
    search_string = expected.translation.title

    actual.find('.js-search-input').fill_in with: search_string
    actual.find('.search-results').has_text? search_string
  end

  description do
    "allows to search for \"#{expected.translation.title}\""
  end

  failure_message do
    "could not search for \"#{expected.translation.title}\""
  end

  failure_message do
    "\"#{expected.translation.title}\" showed up in search results"
  end
end
