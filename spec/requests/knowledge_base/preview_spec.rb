# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'KnowledgeBase preview', authenticated_as: :user, type: :request do
  include_context 'basic Knowledge Base'

  let(:user) { create(:admin) }

  describe '#preview' do
    context 'when no custom URL is set' do
      it 'redirects to given knowledge base' do
        get "/api/v1/knowledge_bases/preview/KnowledgeBase/#{knowledge_base.id}/en"

        expect(response).to redirect_to(%r{^http://www.example.com/help/en})
      end

      it 'redirects to given category' do
        get "/api/v1/knowledge_bases/preview/KnowledgeBaseCategory/#{category.id}/en"

        expect(response).to redirect_to(%r{^http://www.example.com/help/en/#{category.id}})
      end

      it 'redirects to given answer' do
        get "/api/v1/knowledge_bases/preview/KnowledgeBaseCategory/#{published_answer.id}/en"

        expect(response).to redirect_to(%r{^http://www.example.com/help/en/#{published_answer.id}})
      end
    end

    context 'when custom path is set' do
      before do
        knowledge_base.update! custom_address: '/kb'
      end

      it 'redirects to given knowledge base' do
        get "/api/v1/knowledge_bases/preview/KnowledgeBase/#{knowledge_base.id}/en"

        expect(response).to redirect_to(%r{^http://www.example.com/kb/en})
      end

      it 'redirects to given category' do
        get "/api/v1/knowledge_bases/preview/KnowledgeBaseCategory/#{category.id}/en"

        expect(response).to redirect_to(%r{^http://www.example.com/kb/en/#{category.id}})
      end

      it 'redirects to given answer' do
        get "/api/v1/knowledge_bases/preview/KnowledgeBaseCategory/#{published_answer.id}/en"

        expect(response).to redirect_to(%r{^http://www.example.com/kb/en/#{published_answer.id}})
      end
    end

    context 'when custom URL is set' do
      before do
        knowledge_base.update! custom_address: 'kb.example.org'
      end

      it 'redirects to given knowledge base' do
        get "/api/v1/knowledge_bases/preview/KnowledgeBase/#{knowledge_base.id}/en"

        expect(response).to redirect_to(%r{^http://kb.example.org/en})
      end

      it 'redirects to given category' do
        get "/api/v1/knowledge_bases/preview/KnowledgeBaseCategory/#{category.id}/en"

        expect(response).to redirect_to(%r{^http://kb.example.org/en/#{category.id}})
      end

      it 'redirects to given answer' do
        get "/api/v1/knowledge_bases/preview/KnowledgeBaseCategory/#{published_answer.id}/en"

        expect(response).to redirect_to(%r{^http://kb.example.org/en/#{published_answer.id}})
      end
    end
  end
end
