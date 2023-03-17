# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Public Knowledge Base for guest search', searchindex: true, type: :system do
  include_context 'basic Knowledge Base'

  before do
    published_answer && draft_answer && internal_answer

    searchindex_model_reload([KnowledgeBase::Translation, KnowledgeBase::Category::Translation, KnowledgeBase::Answer::Translation])

    visit help_no_locale_path
  end

  it 'shows no results notification for gibberish search' do
    find('.js-search-input').fill_in with: 'Asdasdasdasdasd'
    expect(page).to have_text 'No results were found'
  end

  it 'list published article' do
    expect(page).to produce_search_result_for published_answer
  end

  it 'list draft article' do
    expect(page).to produce_search_result_for draft_answer
  end

  it 'list internal article' do
    expect(page).to produce_search_result_for internal_answer
  end
end
