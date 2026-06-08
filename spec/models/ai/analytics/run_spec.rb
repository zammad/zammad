# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AI::Analytics::Run, type: :model do
  subject(:ai_analytics_run) { create(:ai_analytics_run) }

  it 'has a valid factory' do
    expect(ai_analytics_run).to be_valid
  end

  it { is_expected.to validate_presence_of(:identifier) }
  it { is_expected.to validate_presence_of(:ai_service_name) }
  it { is_expected.to belong_to(:locale).optional }
  it { is_expected.to belong_to(:related_object).optional }
  it { is_expected.to belong_to(:triggered_by).optional }
  it { is_expected.to belong_to(:regeneration_of).class_name('AI::Analytics::Run').optional }
  it { is_expected.to have_many(:regenerations).class_name('AI::Analytics::Run').with_foreign_key('regeneration_of_id').dependent(:nullify) }
  it { is_expected.to have_many(:usages).class_name('AI::Analytics::Usage').with_foreign_key('ai_analytics_run_id').dependent(:destroy) }
  it { is_expected.to have_many(:stored_results).class_name('AI::StoredResult').with_foreign_key('ai_analytics_run_id').dependent(:nullify) }
end
