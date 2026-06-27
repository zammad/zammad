# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe RackAttackSetup do
  describe '.setup' do
    before do
      allow(RackAttackSetup::FormEndpoint).to receive(:setup)
      allow(RackAttackSetup::PublicEndpoint).to receive(:setup)
    end

    it 'calls FormEndpoint' do
      described_class.setup

      expect(RackAttackSetup::FormEndpoint).to have_received(:setup)
    end

    it 'calls PublicEndpoint.setup' do
      described_class.setup

      expect(RackAttackSetup::PublicEndpoint).to have_received(:setup)
    end
  end

  describe '.path_matches?' do
    let(:throttle_path) { '/some/path/to/throttle' }

    it 'returns true when the request path matches the throttle path' do
      expect(described_class).to be_path_matches(throttle_path, throttle_path)
    end

    it 'returns false when the request path does not match the throttle path' do
      expect(described_class).not_to be_path_matches('/some/other/path', throttle_path)
    end

    it 'returns true when the request path matches the throttle path with a format extension' do
      expect(described_class).to be_path_matches("#{throttle_path}.json", throttle_path)
    end

    it 'returns true when the request path has double format extension' do
      expect(described_class).to be_path_matches("#{throttle_path}.json.xml", throttle_path)
    end
  end

  describe '.normalize_param' do
    it 'normalizes the parameter by downcasing and removing whitespace' do
      expect(described_class.normalize_param('  ExAmPlE PaRaMeTeR  ')).to eq('exampleparameter')
    end

    it 'handles unicode characters correctly' do
      expect(described_class.normalize_param('  Üñîçødé  ')).to eq('üñîçødé')
    end

    it 'returns an empty string for nil input' do
      expect(described_class.normalize_param(nil)).to eq('')
    end
  end
end
