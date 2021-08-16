# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Public Knowledge Base answer', type: :system, authenticated_as: false do
  include_context 'basic Knowledge Base'

  context 'video content' do

    before do
      published_answer_with_video
    end

    it 'shows video player' do
      visit help_answer_path(primary_locale.system_locale.locale, category, published_answer_with_video)

      iframe = find('iframe')
      expect(iframe['src']).to start_with('https://www.youtube.com/embed/')
    end
  end

  context 'tags' do
    before do
      visit help_answer_path(locale_name, category, published_answer_with_tag)
    end

    it 'shows an associated tag' do
      expect(page).to have_css('.tags a', text: published_answer_tag_name)
    end

    it 'links to tag page' do
      click '.tags a'

      expect(current_url).to end_with help_tag_path(locale_name, published_answer_tag_name)
    end
  end
end
