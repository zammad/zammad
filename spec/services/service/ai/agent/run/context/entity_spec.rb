# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Agent::Run::Context::Entity, type: :service do
  let(:ticket) { create(:ticket, title: 'Test Ticket', group: group) }
  let(:group)  { create(:group, name: 'Example Group') }
  let(:entity_context) do
    {
      'object_attributes' => %w[title group_id type]
    }
  end
  let(:entity) { described_class.new(entity_object: ticket, entity_context: entity_context) }

  describe '#prepare' do
    context 'when entity_object_attributes is blank' do
      let(:entity_context) do
        {
          object_attributes: []
        }
      end

      it 'returns empty hash' do
        result = entity.prepare
        expect(result[:object_attributes]).to eq(
          'title' => {
            value: 'Test Ticket'
          }
        )
      end
    end

    context 'when entity_object_attributes is present' do
      it 'returns entity object attributes with values and labels' do
        result = entity.prepare

        expect(result[:object_attributes]).to include(
          'title'    => {
            value: 'Test Ticket'
          },
          'group_id' => {
            value: group.id,
            label: 'Example Group'
          }
        )
      end
    end

    context 'when entity_object_attributes includes options field' do
      let(:entity_context) do
        {
          'object_attributes' => %w[title type]
        }
      end

      it 'returns options with value and label' do
        # Set the ticket type to 'Incident'
        ticket.update!(type: 'Incident')

        result = entity.prepare

        expect(result[:object_attributes]).to include(
          'type' => {
            value: 'Incident',
            label: 'Incident'
          }
        )
      end
    end

    context 'when entity_object_attributes includes non-existent field' do
      let(:entity_context) do
        {
          'object_attributes' => %w[title non_existent_field]
        }
      end

      it 'skips non-existent fields', aggregate_failures: true do
        result = entity.prepare

        expect(result[:object_attributes]).to include('title')
        expect(result[:object_attributes]).not_to include('non_existent_field')
      end
    end

    context 'when entity_object_attributes includes default handled field' do
      let(:entity_context) do
        {
          'object_attributes' => %w[title number]
        }
      end

      it 'returns default handling with value only' do
        # Set a numeric value
        ticket.update!(number: '12345')

        result = entity.prepare

        expect(result[:object_attributes]).to include(
          'number' => {
            value: '12345'
          }
        )
      end
    end

    context 'when entity_object_attributes includes blank default field' do
      let(:entity_context) do
        {
          'object_attributes' => %w[title type]
        }
      end

      it 'skips blank values', aggregate_failures: true do
        # Set a blank value
        ticket.update!(type: '')

        result = entity.prepare

        expect(result[:object_attributes]).to include('title')
        expect(result[:object_attributes]).not_to include('type')
      end
    end

    context 'when entity_articles is specified' do
      let(:articles) { create_list(:ticket_article, 3, ticket: ticket, type_name: 'note') }

      before do
        articles
      end

      context 'when articles is set to "all"' do
        let(:entity_context) do
          {
            'object_attributes' => %w[title],
            'articles'          => 'all'
          }
        end

        it 'includes articles setting and processed articles in result' do
          result = entity.prepare

          expect(result[:articles]).to match_array(
            articles.map do |article|
              hash_including(
                article:        article,
                processed_body: be_present
              )
            end
          )
        end
      end

      context 'when articles is set to "last"' do
        let(:entity_context) do
          {
            'object_attributes' => %w[title],
            'articles'          => 'last'
          }
        end

        it 'includes articles setting and only the last processed article in result' do
          result = entity.prepare

          expect(result[:articles]).to contain_exactly(
            hash_including(
              article:        articles.last,
              processed_body: be_present
            )
          )
        end
      end

      context 'when articles is set to "last" and entity_article is provided' do
        let(:specific_article) { articles.second }
        let(:entity) { described_class.new(entity_object: ticket, entity_context: entity_context, entity_article: specific_article) }
        let(:entity_context) do
          {
            'object_attributes' => %w[title],
            'articles'          => 'last'
          }
        end

        it 'includes articles setting and only the specific processed article in result' do
          result = entity.prepare

          expect(result[:articles]).to contain_exactly(
            hash_including(
              article:        specific_article,
              processed_body: be_present
            )
          )
        end
      end

      context 'when articles is set to "first" and entity_article is provided' do
        let(:first_article) { articles.first }
        let(:entity) { described_class.new(entity_object: ticket, entity_context: entity_context) }
        let(:entity_context) do
          {
            'object_attributes' => %w[title],
            'articles'          => 'first'
          }
        end

        it 'includes articles setting and only the specific processed article in result' do
          result = entity.prepare

          expect(result[:articles]).to contain_exactly(
            hash_including(
              article:        first_article,
              processed_body: be_present
            )
          )
        end
      end

      context 'when articles is not specified' do
        let(:entity_context) do
          {
            'object_attributes' => %w[title]
          }
        end

        it 'defaults to "all" and processes all articles' do
          result = entity.prepare

          expect(result[:articles]).to match_array(
            articles.map do |article|
              hash_including(
                article:        article,
                processed_body: be_present
              )
            end
          )
        end
      end
    end
  end
end
