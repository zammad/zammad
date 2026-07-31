# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AI::FeatureProvider, type: :model do
  subject(:feature_provider) { create(:ai_feature_provider) }

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:identifier) }
    it { is_expected.to validate_uniqueness_of(:identifier).case_insensitive }
    it { is_expected.to validate_inclusion_of(:identifier).in_array(described_class.available_identifiers) }
  end

  describe 'Associations' do
    it 'requires a provider_connection' do
      expect(build(:ai_feature_provider, provider_connection: nil)).not_to be_valid
    end
  end

  it 'derives the routable identifiers from the registered AI services, excluding the OCR capability' do
    expect(described_class.available_identifiers)
      .to contain_exactly('ticket_summarize', 'text_tool', 'knowledge_base_answer_from_ticket', 'ai_agent')
  end
end
