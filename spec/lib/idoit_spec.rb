# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Idoit do
  let(:token)    { 'some_token' }
  let(:endpoint) { 'https://idoit.example.com/i-doit/' }
  let(:response) { UserAgent::Result.new(success: true, data: { 'result' => [] }) }
  let(:payloads) { [] }

  before do
    Setting.set('idoit_config', { api_token: token, endpoint: endpoint })
    allow(UserAgent).to receive(:post) do |_url, payload, _options|
      payloads << payload
      response
    end
  end

  def sent_params
    payloads.last[:params]
  end

  describe '.query' do
    it 'adds the enabled filter when requesting object types' do
      described_class.query('cmdb.object_types')

      expect(sent_params[:filter]).to eq({ enabled: true })
    end

    it 'preserves filters given by the caller when requesting object types' do
      described_class.query('cmdb.object_types', { ids: [1] })

      expect(sent_params[:filter]).to eq({ ids: [1], enabled: true })
    end

    it 'tolerates a nil filter' do
      described_class.query('cmdb.object_types', nil)

      expect(sent_params[:filter]).to eq({ enabled: true })
    end

    it 'does not add the enabled filter for other methods' do
      described_class.query('cmdb.objects', { ids: [33] })

      expect(sent_params[:filter]).to eq({ ids: [33] })
    end

    it 'sends no filter for other methods without one' do
      described_class.query('cmdb.objects')

      expect(sent_params).not_to have_key(:filter)
    end

    context 'with a current user' do
      let(:user) { create(:agent, preferences: { locale: 'de-de' }) }

      it 'sends the language of the user locale' do
        UserInfo.with_user_id(user.id) do
          described_class.query('cmdb.objects')
        end

        expect(sent_params[:language]).to eq('de')
      end
    end

    context 'without a current user' do
      before { Setting.set('locale_default', 'fr-fr') }

      it 'sends the language of the default locale' do
        described_class.query('cmdb.objects')

        expect(sent_params[:language]).to eq('fr')
      end
    end
  end

  describe '.verify' do
    it 'requests only enabled object types in the current language' do
      described_class.verify(token, endpoint)

      expect(sent_params).to eq({ apikey: token, language: 'en', filter: { enabled: true } })
    end
  end
end
