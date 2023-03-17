# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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

  context 'with granular permissions', :aggregate_failures do
    before do
      admin = create(:admin)
      internal_answer
      published_answer
      KnowledgeBase::PermissionsUpdate.new(category, admin).update_using_params!(granular_permissions)
    end

    let(:role_admin)   { Role.find_by(name: 'Admin') }
    let(:role_agent)   { Role.find_by(name: 'Agent') }

    let(:granular_permissions) do
      {
        permissions: {
          role_admin.id => 'editor',
          role_agent.id => 'none'
        }
      }
    end

    context 'with admin user' do
      let(:user) { create(:admin) }

      it 'shows answer in root' do
        get feed_knowledge_base_path(knowledge_base, locale_name)

        expect(response).to have_http_status :ok
        expect(response.body).to include internal_answer.translations.first.title
        expect(response.body).to include published_answer.translations.first.title
      end

      it 'shows answer in category' do
        get feed_knowledge_base_category_path(knowledge_base, category, locale_name)

        expect(response).to have_http_status :ok
        expect(response.body).to include internal_answer.translations.first.title
        expect(response.body).to include published_answer.translations.first.title
      end

      context 'with a token', authenticated_as: false do
        let(:token) { Token.ensure_token! 'KnowledgeBaseFeed', user.id }

        it 'shows answer in root' do
          get feed_knowledge_base_path(knowledge_base, locale_name, token: token)

          expect(response).to have_http_status :ok
          expect(response.body).to include internal_answer.translations.first.title
          expect(response.body).to include published_answer.translations.first.title
        end

        it 'shows answer in category' do
          get feed_knowledge_base_category_path(knowledge_base, category, locale_name, token: token)

          expect(response).to have_http_status :ok
          expect(response.body).to include internal_answer.translations.first.title
          expect(response.body).to include published_answer.translations.first.title
        end
      end
    end

    context 'with agent user' do
      let(:user) { create(:agent) }
      let(:token) { Token.ensure_token! 'KnowledgeBaseFeed', user.id }

      it 'does not show answer in root' do
        get feed_knowledge_base_path(knowledge_base, locale_name)

        expect(response).to have_http_status :ok
        expect(response.body).not_to include internal_answer.translations.first.title
        expect(response.body).to include published_answer.translations.first.title
      end

      it 'shows answer in category' do
        get feed_knowledge_base_category_path(knowledge_base, category, locale_name)

        expect(response).to have_http_status :ok
        expect(response.body).not_to include internal_answer.translations.first.title
        expect(response.body).to include published_answer.translations.first.title
      end

      context 'with a token', authenticated_as: false do
        it 'does not show answer in root' do
          get feed_knowledge_base_path(knowledge_base, locale_name, token: token)

          expect(response).to have_http_status :ok
          expect(response.body).not_to include internal_answer.translations.first.title
          expect(response.body).to include published_answer.translations.first.title
        end

        it 'shows answer in category' do
          get feed_knowledge_base_category_path(knowledge_base, category, locale_name, token: token)

          expect(response).to have_http_status :ok
          expect(response.body).not_to include internal_answer.translations.first.title
          expect(response.body).to include published_answer.translations.first.title
        end
      end
    end
  end
end
