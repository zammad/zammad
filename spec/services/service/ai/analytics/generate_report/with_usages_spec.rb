# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require_relative 'ordering_examples'

RSpec.describe Service::AI::Analytics::GenerateReport::WithUsages do
  describe '#execute' do
    let(:ai_analytics_runs) { create_list(:ai_analytics_run, 2) }

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

  describe '.new' do
    it 'raises an error for an unknown format' do
      expect { described_class.new(format: 'csv') }.to raise_error(Exceptions::UnprocessableContent)
    end
  end

  describe '#content_type' do
    it 'returns the content type of the format' do
      expect(described_class.new(format: 'xlsx').content_type).to eq(ExcelSheet::CONTENT_TYPE)
    end
  end

  describe '#each_parsed_record' do
    context 'when no records exist' do
      it 'returns an empty array' do
        expect(described_class.new.send(:each_parsed_record).to_a).to be_empty
      end
    end

    context 'when a record exists without usages' do
      let(:ai_analytics_run) { create(:ai_analytics_run) }

      before { ai_analytics_run }

      it 'returns the parsed record' do
        expect(described_class.new.send(:each_parsed_record).to_a)
          .to contain_exactly(
            include(
              id:             ai_analytics_run.id,
              usages_count:   0,
              likes_count:    0,
              dislikes_count: 0,
              ratings:        [],
              comments:       []
            )
          )
      end

      context 'when a record with an error exists' do
        it 'does not include that record' do
          create(:ai_analytics_run, :with_error)

          expect(described_class.new.send(:each_parsed_record).to_a)
            .to contain_exactly(
              include(
                id: ai_analytics_run.id,
              )
            )
        end
      end
    end

    context 'when a record exists with some usages' do
      let(:user)                 { create(:agent) }
      let(:user_2)               { create(:agent) }
      let(:ai_analytics_run)     { create(:ai_analytics_run) }
      let(:ai_analytics_usage)   { create(:ai_analytics_usage, rating: true, ai_analytics_run:, user:) }
      let(:ai_analytics_usage_2) { create(:ai_analytics_usage, rating: false, comment: 'some comment here', ai_analytics_run:, user: user_2) }
      let(:ai_analytics_run_2)   { create(:ai_analytics_run) }
      let(:ai_analytics_usage_3) { create(:ai_analytics_usage, ai_analytics_run: ai_analytics_run_2, user:) }
      let(:ai_analytics_run_3)   { create(:ai_analytics_run) }

      before do
        ai_analytics_usage
        ai_analytics_usage_2
        ai_analytics_usage_3
        ai_analytics_run_3
      end

      it 'returns the parsed record' do
        expect(described_class.new.send(:each_parsed_record).to_a)
          .to contain_exactly(
            include(
              id:             ai_analytics_run.id,
              usages_count:   2,
              likes_count:    1,
              dislikes_count: 1,
              ratings:        contain_exactly(
                { user_id: user.id, rating: true, user_login: user.login },
                { user_id: user_2.id, rating: false, user_login: user_2.login }
              ),
              comments:       [{
                user_id:    user_2.id,
                comment:    'some comment here',
                created_at: ai_analytics_usage_2.created_at,
                rating:     false,
                user_login: user_2.login
              }]
            ),
            include(
              id:             ai_analytics_run_2.id,
              usages_count:   1,
              likes_count:    0,
              dislikes_count: 0,
              ratings:        [],
              comments:       []
            ),
            include(
              id:             ai_analytics_run_3.id,
              usages_count:   0,
              likes_count:    0,
              dislikes_count: 0,
              ratings:        [],
              comments:       []
            )
          )
      end
    end

    context 'when a scope is given' do
      let(:ticket) { create(:ticket) }
      let(:ai_analytics_run)   { create(:ai_analytics_run, related_object: ticket) }
      let(:ai_analytics_run_2) { create(:ai_analytics_run) }

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
    let(:ai_analytics_runs) { create_list(:ai_analytics_run, 10) }
  end
end
