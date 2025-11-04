# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'AI::Analytics::DownloadsController', :aggregate_failures, authenticated_as: :user, type: :request do
  describe '#download' do
    before do
      ai_analytics_run
      get "/api/v1/ai/analytics/download/#{type}", params: { format:, filters: }
    end

    let(:format)           { nil }
    let(:filters)          { nil }
    let(:ai_analytics_run) { create(:ai_analytics_run, related_object: ticket) }
    let(:ticket)           { create(:ticket) }
    let(:user)             { create(:admin) }

    shared_examples 'handles permissions' do
      context 'when user has admin.ai_provider permission' do
        it 'response is success' do
          expect(response).to have_http_status(:ok)
        end
      end

      context 'when user does not have admin.ai_provider permission' do
        let(:user) { create(:agent) }

        it 'response is forbidden' do
          expect(response).to have_http_status(:forbidden)
        end
      end

      context 'when user is customer' do
        let(:user) { create(:customer) }

        it 'response is forbidden' do
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    shared_examples 'returns basic data' do
      it 'returns xlsx by default' do
        expect(response.content_type).to eq(ExcelSheet::CONTENT_TYPE)
      end

      context 'when format is json' do
        let(:format) { 'json' }

        it 'response is success' do
          expect(response).to have_http_status(:ok)
        end

        it 'returns json content type' do
          expect(response.content_type).to eq('application/json')
        end
      end
    end

    shared_examples 'handles filtering correctly' do
      context 'when checking filters' do
        let(:format) { 'json' }

        shared_examples 'finds the record' do
          it 'finds the record' do
            expect(response.parsed_body).to contain_exactly(include(id: ai_analytics_run.id))
          end
        end

        shared_examples 'finds no record' do
          it 'finds no record' do
            expect(response.parsed_body).to be_empty
          end
        end

        include_examples 'finds the record'

        shared_examples 'check filter type' do |filter_name|
          context 'with matching filter' do
            let(:filters) { { filter_name => matching_value } }

            include_examples 'finds the record'
          end

          context 'with non-matching filter' do
            let(:filters) { { filter_name => nonmatching_value } }

            include_examples 'finds no record'
          end
        end

        context 'when filtering for ai_service_name' do
          let(:matching_value) { ai_analytics_run.ai_service_name }
          let(:nonmatching_value) { 'nonexisting' }

          include_examples 'check filter type', :ai_service_name
        end

        context 'when filtering for related_object_type' do
          let(:matching_value) { 'Ticket' }
          let(:nonmatching_value) { 'Article' }

          include_examples 'check filter type', :related_object_type
        end

        context 'when filtering for related_object_id' do
          let(:matching_value) { ticket.id }
          let(:nonmatching_value) { -1 }

          include_examples 'check filter type', :related_object_id
        end

        context 'when filtering for created_before' do
          let(:matching_value) { ai_analytics_run.created_at + 1.hour }
          let(:nonmatching_value) { ai_analytics_run.created_at - 1.hour }

          include_examples 'check filter type', :created_before
        end

        context 'when filtering for created_after' do
          let(:matching_value) { ai_analytics_run.created_at - 1.hour }
          let(:nonmatching_value) { ai_analytics_run.created_at + 1.hour }

          include_examples 'check filter type', :created_after
        end
      end
    end

    context 'with download type with_usages' do
      let(:type) { 'with_usages' }

      include_examples 'handles permissions'
      include_examples 'returns basic data'
      include_examples 'handles filtering correctly'

    end

    context 'with download type errors' do
      let(:type)             { 'errors' }
      let(:ai_analytics_run) { create(:ai_analytics_run, :with_error, related_object: ticket) }

      include_examples 'handles permissions'
      include_examples 'returns basic data'
      include_examples 'handles filtering correctly'
    end
  end
end
