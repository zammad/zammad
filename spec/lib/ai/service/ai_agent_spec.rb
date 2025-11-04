# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AI::Service::AIAgent, :aggregate_failures do
  subject(:ai_service) { described_class.new(current_user:, context_data:, additional_options:) }

  let(:ticket)   { create(:ticket, title: 'Test Ticket', group: group, priority: priority) }
  let(:group)    { create(:group, name: 'Support Team') }
  let(:priority) { Ticket::Priority.lookup(name: '2 normal') }
  let(:context_data) do
    {
      ticket:              ticket,
      role_description:    'Test AI Agent',
      instruction:         'Analyze the ticket and provide recommendations',
      instruction_context: {
        object_attributes: {
          'priority_id' => {
            label: 'Priority',
            items: [
              { value: 1, label: '1 low', description: 'Low priority' },
              { value: 2, label: '2 normal', description: 'Normal priority' },
              { value: 3, label: '3 high', description: 'High priority' }
            ]
          }
        }
      },
      entity_context:      {
        object_attributes: {
          'title'       => {
            value: 'Test Ticket'
          },
          'group_id'    => {
            value: group.id,
            label: 'Support Team'
          },
          'priority_id' => {
            value: priority.id,
            label: '2 normal'
          }
        }
      },
      result_structure:    {
        'state_id'    => 'integer',
        'priority_id' => 'integer'
      }
    }
  end
  let(:additional_options) { { json_response: true } }
  let(:current_user)   { create(:user) }
  let(:mock_provider)  { instance_spy(AI::Provider::OpenAI) }
  let(:mock_result)    { { 'state_id' => 1, 'priority_id' => 2 } }

  before do
    setup_ai_provider('open_ai')

    # Mock the provider to avoid real API calls
    allow(AI::Provider::OpenAI).to receive(:new).and_return(mock_provider)
    allow(mock_provider).to receive(:ask).and_return(mock_result)
  end

  it 'calls the provider with the expected prompts' do
    result = ai_service.execute

    expect(mock_provider).to have_received(:ask) do |args|
      expect(args[:prompt_system]).to be_present
      expect(args[:prompt_user]).to be_present
      expect(args[:prompt_system]).to include('Test AI Agent')
      expect(args[:prompt_system]).to include('Analyze the ticket and provide recommendations')

      # Check for the complete XML structure for priority_id (with extra newlines from ERB)
      expect(args[:prompt_system]).to include(<<~XML.strip)
        The available options from "Priority" are definied inside the XML format:
        <priority_id>
          <option>
            <value>1</value>
            <label>1 low</label>
          </option>
          <option>
            <value>2</value>
            <label>2 normal</label>
          </option>
          <option>
            <value>3</value>
            <label>3 high</label>
          </option>
        </priority_id>
      XML

      # Check for the complete JSON response structure (pretty-printed JSON format)
      expect(args[:prompt_system]).to include(<<~JSON.strip)
        Reply in the defined plain JSON structure only and do not wrap it in code block markers:

        {
          "state_id": "integer",
          "priority_id": "integer"
        }
      JSON

      # Check for entity context in the user prompt
      expect(args[:prompt_user]).to include(<<~XML.strip)
        <ticket>
          <title>
            <value>Test Ticket</value>
          </title>
          <group_id>
            <label>Support Team</label>
            <value>#{group.id}</value>
          </group_id>
          <priority_id>
            <label>2 normal</label>
            <value>#{priority.id}</value>
          </priority_id>

        </ticket>
      XML
    end

    expect(result.content).to include('state_id' => 1, 'priority_id' => 2)
  end

  context 'when entity_context has object_attributes with only values (no labels)' do
    let(:context_data) do
      {
        ticket:              ticket,
        role_description:    'Test AI Agent',
        instruction:         'Analyze the ticket and provide recommendations',
        instruction_context: {
          object_attributes: {}
        },
        entity_context:      {
          object_attributes: {
            'title' => {
              value: 'Test Ticket'
            }
          }
        },
        result_structure:    {
          'state_id' => 'integer'
        }
      }
    end

    it 'includes only value without label in the prompt' do
      result = ai_service.execute

      expect(mock_provider).to have_received(:ask) do |args|
        expect(args[:prompt_user]).to include(<<~XML.strip)
          <ticket>
            <title>
              <value>Test Ticket</value>
            </title>
        XML
      end

      expect(result.content).to include('state_id' => 1)
    end
  end

  context 'when entity_context has articles setting' do
    let(:articles) { create_list(:ticket_article, 3, ticket: ticket) }

    before do
      articles
    end

    context 'when articles is set to "all"' do
      let(:context_data) do
        {
          ticket:              ticket,
          role_description:    'Test AI Agent',
          instruction:         'Analyze the ticket and provide recommendations',
          instruction_context: {
            object_attributes: {}
          },
          entity_context:      {
            object_attributes: {
              'title' => {
                value: 'Test Ticket'
              }
            },
            articles:          articles.map do |article|
              {
                article:        article,
                processed_body: article.body_as_text
              }
            end
          },
          result_structure:    {
            'state_id' => 'integer'
          }
        }
      end

      it 'includes all articles in the prompt' do
        result = ai_service.execute

        expect(mock_provider).to have_received(:ask) do |args|
          # Should include all 3 articles with their content
          expect(args[:prompt_user].scan('<article>').count).to eq(3)
          articles.each do |article|
            expect(args[:prompt_user]).to include(article.body_as_text)
          end
        end

        expect(result.content).to include('state_id' => 1)
      end
    end

    context 'when articles is set to "last"' do
      let(:context_data) do
        {
          ticket:              ticket,
          role_description:    'Test AI Agent',
          instruction:         'Analyze the ticket and provide recommendations',
          instruction_context: {
            object_attributes: {}
          },
          entity_context:      {
            object_attributes: {
              'title' => {
                value: 'Test Ticket'
              }
            },
            articles:          [{
              article:        articles.last,
              processed_body: articles.last.body_as_text
            }]
          },
          result_structure:    {
            'state_id' => 'integer'
          }
        }
      end

      it 'includes only the last article in the prompt' do
        result = ai_service.execute

        expect(mock_provider).to have_received(:ask) do |args|
          # Should include only 1 article (the last one)
          expect(args[:prompt_user]).to include('<article>')
          expect(args[:prompt_user].scan('<article>').count).to eq(1)
        end

        expect(result.content).to include('state_id' => 1)
      end
    end

    context 'when articles is set to "last" and context_data has article' do
      let(:specific_article) { articles.first }
      let(:context_data) do
        {
          ticket:              ticket,
          article:             specific_article,
          role_description:    'Test AI Agent',
          instruction:         'Analyze the ticket and provide recommendations',
          instruction_context: {
            object_attributes: {}
          },
          entity_context:      {
            object_attributes: {
              'title' => {
                value: 'Test Ticket'
              }
            },
            articles:          [{
              article:        specific_article,
              processed_body: specific_article.body_as_text
            }]
          },
          result_structure:    {
            'state_id' => 'integer'
          }
        }
      end

      it 'includes only the specific article from context_data in the prompt' do
        result = ai_service.execute

        expect(mock_provider).to have_received(:ask) do |args|
          # Should include only 1 article (the specific one from context_data)
          expect(args[:prompt_user]).to include('<article>')
          expect(args[:prompt_user].scan('<article>').count).to eq(1)
          # Should include the specific article's content
          expect(args[:prompt_user]).to include(specific_article.body_as_text)
        end

        expect(result.content).to include('state_id' => 1)
      end
    end
  end
end
