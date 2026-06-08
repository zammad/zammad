# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'ordering items correctly and returning latest entries' do
  before do
    stub_const('Service::AI::Analytics::GenerateReport::Base::BATCH_SIZE', 2)
    stub_const('Service::AI::Analytics::GenerateReport::Base::RESULT_SIZE', 6)
  end

  it 'returns latest records' do
    ai_analytics_runs

    parsed_records = described_class.new.send(:parsed_records)

    expect(parsed_records.pluck(:id)).to eq(ai_analytics_runs.last(6).map(&:id).reverse)
  end
end
