# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'System Assets', type: :request do
  let(:admin) { create(:admin) }

  describe 'GET /translations/customized', authenticated_as: :admin do
    before do
      create(:translation, locale: 'de-de', source: 'A example', target: 'Ein Beispiel')
    end

    it 'returns the customized list of translations' do
      get '/api/v1/translations/customized'

      expect(json_response.count).to eq(1)
    end
  end

  describe 'GET /translations/search/:locale', authenticated_as: :admin do
    let(:query) { SecureRandom.uuid }

    before do
      create(:translation, locale: 'de-de', source: 'A example', target: "Ein Beispiel #{query}", is_synchronized_from_codebase: true)
    end

    it 'returns the filtered translations' do
      get '/api/v1/translations/search/de-de', params: { query: }

      expect(json_response['items'].count).to eq(1)
    end
  end

  describe 'POST /translations/upsert', :aggregate_failures, authenticated_as: :admin do
    let(:locale)                      { 'de-de' }
    let(:source)                      { SecureRandom.uuid }
    let(:target)                      { 'Other' }

    it 'creates a new translation record' do
      expect do
        post '/api/v1/translations/upsert', params: { source:, locale:, target: }
      end.to change(Translation, :count).by(1)

      expect(json_response).to include('locale' => locale, 'source' => source, 'target' => target)
    end
  end

  describe 'PUT /translations/reset/:id', :aggregate_failures, authenticated_as: :admin do
    let(:translation) { Translation.find_by(locale: 'de-de', source: 'New') }

    before do
      translation.update!(target: 'Neu!')
    end

    it 'resets translation record' do
      expect do
        put "/api/v1/translations/reset/#{translation.id}"
      end.to change { translation.reload.target }.to(translation.target_initial)
    end
  end
end
