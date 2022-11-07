# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'KnowledgeBase feed', authenticated_as: :user, type: :request do
  include_context 'basic Knowledge Base'

  let(:user) { create(:admin) }

  before do
    published_answer
    travel 1.minute
    published_answer_in_other_category
  end

  describe '#root' do
    before do
      get feed_knowledge_base_path(knowledge_base, locale_name)
    end

    it 'lists entries' do
      answer_index = response.body.index published_answer.translations.first.title
      answer_index2 = response.body.index published_answer_in_other_category.translations.first.title

      expect(answer_index > answer_index2).to be_truthy
    end

    it 'uses KB title' do
      expect(response.body).to include(knowledge_base.translations.first.title)
    end

  end

  describe '#category' do
    before do
      get feed_knowledge_base_category_path(knowledge_base, category, locale_name)
    end

    it 'lists entries', :aggregate_failures do
      expect(response.body).to include(published_answer.translations.first.title)
      expect(response.body).not_to include(published_answer_in_other_category.translations.first.title)
    end

    it 'uses category title' do
      expect(response.body).to include(category.translations.first.title)
    end
  end

  context 'with complex answers' do
    it 'sanitizes bodies', :aggregate_failures do
      published_answer_with_video
      published_answer_with_image

      get feed_knowledge_base_path(knowledge_base, locale_name)

      expect(response.body).not_to include('img')
      expect(response.body).not_to include('widget:')
    end
  end

  context 'with no answers' do
    before do
      Ticket.destroy_all
    end

    it 'loads' do
      get feed_knowledge_base_path(knowledge_base, locale_name)

      expect(response).to have_http_status :ok
    end
  end
end
