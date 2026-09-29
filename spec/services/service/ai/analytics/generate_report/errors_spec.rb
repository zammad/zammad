# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require_relative 'ordering_examples'

RSpec.describe Service::AI::Analytics::GenerateReport::Errors do
  describe '#execute' do
    let(:ai_analytics_runs) { create_list(:ai_analytics_run, 2, :with_error) }

    before { ai_analytics_runs }

    context 'when format is xlsx' do
      subject(:generated_file) { described_class.execute(format: :xlsx) }

      after { generated_file.close }

      it 'returns the report as an XLSX file' do
        expect(generated_file.read(2)).to eq('PK')
      end

      include_examples 'not leaving the generated file on disk', prefix: 'excel-export'
    end

    context 'when format is json' do
      subject(:generated_file) { described_class.execute(format: :json) }

      after { generated_file.close }

      it 'returns the report as a JSON file' do
        expect(JSON.parse(generated_file.read))
          .to match_array(ai_analytics_runs.map { |run| include('id' => run.id) })
      end

      include_examples 'not leaving the generated file on disk', prefix: 'ai-analytics'

      context 'without records' do
        let(:ai_analytics_runs) { [] }

        it 'returns an empty JSON array' do
          expect(JSON.parse(generated_file.read)).to eq([])
        end
      end
    end
  end

  describe '#each_parsed_record' do
    context 'when no records exist' do
      it 'returns an empty array' do
        expect(described_class.new.send(:each_parsed_record).to_a).to be_empty
      end
    end

    context 'when a record exists without usages' do
      let(:ai_analytics_run) { create(:ai_analytics_run, :with_error) }

      before { ai_analytics_run }

      it 'returns the parsed record' do
        expect(described_class.new.send(:each_parsed_record).to_a)
          .to contain_exactly(
            include(
              id:    ai_analytics_run.id,
              error: { 'message' => 'some error' }
            )
          )
      end

      context 'when a regular record exists' do
        it 'does not include that record' do
          create(:ai_analytics_run)

          expect(described_class.new.send(:each_parsed_record).to_a)
            .to contain_exactly(
              include(
                id: ai_analytics_run.id,
              )
            )
        end
      end
    end

    context 'when a scope is given' do
      let(:ticket)             { create(:ticket) }
      let(:ai_analytics_run)   { create(:ai_analytics_run, :with_error, related_object: ticket) }
      let(:ai_analytics_run_2) { create(:ai_analytics_run, :with_error) }

      before do
        ai_analytics_run
        ai_analytics_run_2
      end

      it 'returns records within the scope' do
        scope = AI::Analytics::Run.where(related_object: ticket)

        expect(described_class.new(scope:).send(:each_parsed_record).to_a)
          .to contain_exactly(
            include(
              id: ai_analytics_run.id,
            )
          )
      end
    end
  end

  it_behaves_like 'ordering items correctly and returning latest entries' do
    let(:ai_analytics_runs) { create_list(:ai_analytics_run, 10, :with_error) }
  end
end
