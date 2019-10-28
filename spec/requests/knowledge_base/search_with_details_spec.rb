require 'rails_helper'

RSpec.describe 'Knowledge Base search with details', type: :request, searchindex: true do
  include_context 'basic Knowledge Base'

  before do
    configure_elasticsearch(required: true, rebuild: true) do
      published_answer
    end
  end

  let(:endpoint) { '/api/v1/knowledge_bases/search' }

  context 'ensure details ID type matches ES ID type' do
    it 'for answers' do
      post endpoint, params: { query: published_answer.translations.first.title }

      expect(json_response['details'][0]['id']).to be_a_kind_of String
    end

    it 'for categories' do
      post endpoint, params: { query: category.translations.first.title }

      expect(json_response['details'][0]['id']).to be_a_kind_of String
    end

    it 'for knowledge base' do
      post endpoint, params: { query: knowledge_base.translations.first.title }

      expect(json_response['details'][0]['id']).to be_a_kind_of String
    end
  end
end
