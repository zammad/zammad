# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe SearchIndexBackend, 'version_handling' do
  describe '.configured?' do
    before do
      Setting.set('es_url', es_value)
    end

    context 'with active setting' do
      let(:es_value) { 'http://localhost:9200' }

      it 'returns true' do
        expect(described_class).to be_configured
      end
    end

    context 'with inactive setting' do
      let(:es_value) { nil }

      it 'returns true' do
        expect(described_class).not_to be_configured
      end
    end
  end

  describe '.info' do
    before do
      Setting.set('es_url', 'http://localhost:9200')
      allow(described_class).to receive(:make_request).and_return(response)
    end

    let(:response) { instance_double(UserAgent::Result, success?: true, data: { 'version' => { 'number' => version } }) }

    context 'with allowed version' do
      let(:version) { '8.1.12' }

      it 'returns correct information' do
        expect(described_class.info).to eq({ 'version' => { 'number' => version } })
      end
    end

    context 'with version too low' do
      let(:version) { '7.0.0' }

      it 'returns correct information' do
        expect { described_class.info }.to raise_error(RuntimeError, "Version #{version} of configured elasticsearch is not supported.")
      end
    end

    context 'with version too high' do
      let(:version) { '9.0.0' }

      it 'returns correct information' do
        expect { described_class.info }.to raise_error(RuntimeError, "Version #{version} of configured elasticsearch is not supported.")
      end
    end
  end

  describe '.version' do
    it 'returns the version' do
      allow(described_class).to receive(:info).and_return({ 'version' => { 'number' => '7.12.0' } })
      expect(described_class.version).to eq('7.12.0')
    end
  end

end
