# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/application_model_examples'
require 'models/concerns/has_optional_groups_examples'
require 'models/concerns/has_xss_sanitized_note_examples'

RSpec.describe AI::TextTool, type: :model do
  it_behaves_like 'ApplicationModel', can_create_update: { unique_name: true }
  it_behaves_like 'HasOptionalGroups', model_factory: :ai_text_tool
  it_behaves_like 'HasXssSanitizedNote', model_factory: :ai_text_tool

  describe 'analytics_stats_reset_at' do
    it 'is nil by default' do
      tool = create(:ai_text_tool)
      expect(tool.reload.analytics_stats_reset_at).to be_nil
    end

    it 'persists analytics_stats_reset_at' do
      time = Time.zone.parse('2025-06-01 12:00:00')
      tool = create(:ai_text_tool, analytics_stats_reset_at: time)
      expect(tool.reload.analytics_stats_reset_at).to be_within(1.second).of(time)
    end
  end

  describe '#satisfaction_ratio' do
    let(:tool) { create(:ai_text_tool) }
    let(:expected_result) do
      { positive: { count: 10, ratio: 50.0 }, negative: { count: 5, ratio: 25.0 }, neutral: { count: 5, ratio: 25.0 } }
    end

    it 'returns the response from Service::AI::Analytics::AggregateSatisfactionRatio' do
      allow(Service::AI::Analytics::AggregateSatisfactionRatio)
        .to receive_message_chain(:new, :execute) { expected_result } # rubocop:disable RSpec/MessageChain

      expect(tool.satisfaction_ratio).to eq(expected_result)
    end
  end

  describe '#attributes_with_association_ids' do
    let(:tool) { create(:ai_text_tool) }

    it 'includes analytics_stats when UserInfo user has admin.ai_assistance_text_tools' do
      UserInfo.with_user_id(create(:admin).id) do
        expect(tool.attributes_with_association_ids).to have_key(described_class::ASSETS_ANALYTICS_STATS_KEY)
      end
    end

    it 'omits analytics_stats when UserInfo user lacks admin.ai_assistance_text_tools' do
      UserInfo.with_user_id(create(:agent).id) do
        expect(tool.attributes_with_association_ids).not_to have_key(described_class::ASSETS_ANALYTICS_STATS_KEY)
      end
    end
  end

end
