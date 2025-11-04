# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Agent::Run do
  let(:ai_agent) { create(:ai_agent, definition: agent_definition, action_definition: action_definition) }
  let(:ticket)   { create(:ticket) }
  let(:agent_definition) do
    {
      'role_description'    => 'Test AI Agent',
      'instruction'         => 'Analyze the ticket and provide recommendations',
      'instruction_context' => instruction_context,
      'result_structure'    => result_structure
    }
  end
  let(:instruction_context) do
    {
      'object_attributes' => {}
    }
  end
  let(:result_structure) do
    {
      'state_id'    => 'integer',
      'priority_id' => 'integer',
    }
  end
  let(:action_definition) do
    {
      'mapping' => {
        'ticket.priority_id' => {
          'value' => '#{ai_agent_result.priority_id}' # rubocop:disable Lint/InterpolationCheck
        },
        'ticket.state_id'    => {
          'value' => '#{ai_agent_result.state_id}' # rubocop:disable Lint/InterpolationCheck
        }
      }
    }
  end
  let(:ai_provider) { 'open_ai' }

  before do
    if ai_provider.present?
      setup_ai_provider(ai_provider, token: ENV['OPEN_AI_TOKEN'])
    else
      unset_ai_provider
    end
  end

  describe '#execute' do
    subject(:service) { described_class.new(ai_agent: ai_agent, ticket: ticket) }

    context 'when AI service returns a successful result' do
      let(:ai_result_content) do
        {
          'state_id'    => Ticket::State.lookup(name: 'open').id,
          'priority_id' => Ticket::Priority.lookup(name: '3 high').id,
        }
      end
      let(:ai_result) do
        AI::Service::Result.new(
          content:       ai_result_content,
          stored_result: nil,
          fresh:         true
        )
      end

      before do
        allow_any_instance_of(AI::Service::AIAgent).to receive(:execute).and_return(ai_result)
      end

      it 'executes the AI agent service and applies changes to the ticket based on AI result' do
        expect { service.execute }
          .to change { ticket.reload.priority.name }.to('3 high')
          .and change { ticket.reload.state.name }.to('open')
      end

      context 'when no result structure is present' do
        let(:result_structure) { nil }
        let(:action_definition) do
          {
            'mapping' => {
              'ticket.priority_id' => {
                'value' => '#{ai_agent_result.content}' # rubocop:disable Lint/InterpolationCheck
              },
            }
          }
        end
        let(:ai_result_content) { Ticket::Priority.lookup(name: '3 high').id }

        it 'executes the AI agent service and applies changes to the ticket based on AI result' do
          expect { service.execute }.to change { ticket.reload.priority.name }.to('3 high')
        end
      end

      context 'when conditions are present in action_definition' do
        let(:result_structure) do
          {
            'state_id'         => 'integer',
            'priority_id'      => 'integer',
            'is_real_question' => 'boolean'
          }
        end
        let(:action_definition) do
          {
            'mapping'    => {
              'ticket.priority_id' => {
                'value' => '#{ai_agent_result.priority_id}' # rubocop:disable Lint/InterpolationCheck
              }
            },
            'conditions' => [
              {
                'condition' => {
                  'is_real_question' => false
                },
                'mapping'   => {
                  'ticket.state_id' => {
                    'value' => '#{ai_agent_result.state_id}' # rubocop:disable Lint/InterpolationCheck
                  }
                }
              }
            ]
          }
        end
        let(:ai_result_content) do
          {
            'priority_id'      => Ticket::Priority.lookup(name: '3 high').id,
            'state_id'         => Ticket::State.lookup(name: 'closed').id,
            'is_real_question' => false
          }
        end

        it 'applies base mapping and condition mapping when condition matches' do
          expect { service.execute }
            .to change { ticket.reload.priority.name }.to('3 high')
            .and change { ticket.reload.state.name }.to('closed')
        end

        context 'when condition does not match' do
          let(:ai_result_content) do
            {
              'priority_id'      => Ticket::Priority.lookup(name: '3 high').id,
              'state_id'         => Ticket::State.lookup(name: 'closed').id,
              'is_real_question' => true
            }
          end

          it 'applies only base mapping when condition does not match' do
            expect { service.execute }
              .to change { ticket.reload.priority.name }.to('3 high')
              .and not_change { ticket.reload.state.name }
          end
        end
      end
    end

    context 'when AI agent has an agent_type' do
      let(:ai_agent) { create(:ai_agent, agent_type: 'TicketGroupDispatcher', definition: agent_definition, action_definition: action_definition) }
      let(:agent_definition) do
        {
          'instruction_context' => {
            'object_attributes' => {
              'group_id' => { Group.first.id.to_s => 'Primary support group for general inquiries' }
            }
          }
        }
      end
      let(:action_definition) do
        {
          'mapping' => {
            'ticket.group_id' => {
              'value' => '#{ai_agent_result.group_id}' # rubocop:disable Lint/InterpolationCheck
            }
          }
        }
      end
      let(:ai_result_content) do
        {
          'group_id' => Group.first.id,
        }
      end
      let(:ai_result) do
        AI::Service::Result.new(
          content:       ai_result_content,
          stored_result: nil,
          fresh:         true
        )
      end

      before do
        allow_any_instance_of(AI::Service::AIAgent).to receive(:execute).and_return(ai_result)
      end

      it 'executes with merged definitions from agent type and database' do
        expect { service.execute }
          .to change { ticket.reload.group.name }.to(Group.first.name)
      end

      it 'uses merged role description from agent type and database' do
        # Spy on the AI service to verify it receives the merged definition
        ai_service_spy = instance_double(AI::Service::AIAgent)
        allow(AI::Service::AIAgent).to receive(:new).and_return(ai_service_spy)
        allow(ai_service_spy).to receive(:execute).and_return(ai_result)

        service.execute

        # Verify that the AI service was called with the merged definition
        expect(AI::Service::AIAgent).to have_received(:new).with(
          hash_including(
            context_data: hash_including(
              role_description: 'You are a ticket routing specialist who analyzes ticket content and assigns tickets to the most appropriate group based on the topic and context.'
            )
          )
        )
      end
    end

    context 'when AI agent has TicketCategorizer agent_type', db_strategy: :reset do
      let(:ai_agent) { create(:ai_agent, agent_type: 'TicketCategorizer', definition: agent_definition, type_enrichment_data: type_enrichment_data) }
      let(:type_enrichment_data) { { 'category' => 'custom_category', 'multiple' => false } }
      let(:agent_definition) do
        {
          'instruction_context' => {
            'object_attributes' => {
              'placeholder.category' => {
                'technical_support' => 'Technical issues and troubleshooting',
                'billing'           => 'Payment and billing related questions',
                'feature_request'   => 'Requests for new features or improvements',
                'bug_report'        => 'Reports of software bugs or issues'
              }
            }
          }
        }
      end
      let(:ai_result_content) do
        {
          'custom_category' => 'technical_support',
        }
      end
      let(:ai_result) do
        AI::Service::Result.new(
          content:       ai_result_content,
          stored_result: nil,
          fresh:         true
        )
      end

      before do
        # Create the custom category attribute
        create(:object_manager_attribute_select, object_name: 'Ticket', name: 'custom_category', display: 'Custom Category', data_option_options: { 'technical_support' => 'Technical support', 'billing' => 'Billing', 'feature_request' => 'Feature request', 'bug_report' => 'Bug report' })
        ObjectManager::Attribute.migration_execute

        allow_any_instance_of(AI::Service::AIAgent).to receive(:execute).and_return(ai_result)
      end

      it 'executes with placeholder replacement and applies categorization' do
        expect { service.execute }
          .to change { ticket.reload.custom_category }.from('').to('technical_support')
      end

      it 'passes categories to AI service middleware' do
        # Spy on the AI service to verify it receives the categories
        ai_service_spy = instance_double(AI::Service::AIAgent)
        allow(AI::Service::AIAgent).to receive(:new).and_return(ai_service_spy)
        allow(ai_service_spy).to receive(:execute).and_return(ai_result)

        service.execute

        # Verify that the AI service was called with the categories in the context
        expect(AI::Service::AIAgent).to have_received(:new).with(
          hash_including(
            context_data: hash_including(
              instruction_context: {
                object_attributes: {
                  'custom_category' => {
                    label: 'Custom Category',
                    items: array_including(
                      {
                        value:       'technical_support',
                        label:       'Technical support',
                        description: 'Technical issues and troubleshooting'
                      },
                      {
                        value:       'billing',
                        label:       'Billing',
                        description: 'Payment and billing related questions'
                      },
                      {
                        value:       'feature_request',
                        label:       'Feature request',
                        description: 'Requests for new features or improvements'
                      },
                      {
                        value:       'bug_report',
                        label:       'Bug report',
                        description: 'Reports of software bugs or issues'
                      }
                    )
                  }
                }
              }
            )
          )
        )
      end
    end

    context 'when AI agent handles multiselect field', db_strategy: :reset do
      let(:instruction_context) do
        {
          'object_attributes' => {
            'custom_multiselect' => {
              'key_1' => 'Option 1',
              'key_2' => 'Option 2',
              'key_3' => 'Option 3'
            }
          }
        }
      end
      let(:result_structure) do
        {
          'custom_multiselect' => '[array]'
        }
      end
      let(:action_definition) do
        {
          'mapping' => {
            'ticket.custom_multiselect' => {
              'value' => '#{ai_agent_result.custom_multiselect}' # rubocop:disable Lint/InterpolationCheck
            }
          }
        }
      end
      let(:ai_result_content) do
        {
          'custom_multiselect' => %w[key_1 key_3]
        }
      end
      let(:ai_result) do
        AI::Service::Result.new(
          content:       ai_result_content,
          stored_result: nil,
          fresh:         true
        )
      end

      before do
        # Create the multiselect attribute
        create(:object_manager_attribute_multiselect, object_name: 'Ticket', name: 'custom_multiselect')
        ObjectManager::Attribute.migration_execute

        allow_any_instance_of(AI::Service::AIAgent).to receive(:execute).and_return(ai_result)
      end

      it 'executes the AI agent service and applies multiple values to the multiselect field' do
        expect { service.execute }
          .to change { ticket.reload.custom_multiselect }.from([]).to(%w[key_1 key_3])
      end
    end

    context 'when AI service raises an exception' do
      before do
        allow_any_instance_of(AI::Service::AIAgent).to receive(:execute).and_raise(AI::Provider::OutputFormatError, 'AI service error')
      end

      it 'raises the exception' do
        expect { service.execute }.to raise_error(Service::AI::Agent::Run::PermanentError, 'AI service error')
      end

      context 'when AI service raises an response error' do
        before do
          allow_any_instance_of(AI::Service::AIAgent).to receive(:execute).and_raise(AI::Provider::ResponseError, 'AI service error')
        end

        it 'raises the exception' do
          expect { service.execute }.to raise_error(Service::AI::Agent::Run::TemporaryError, 'AI service error')
        end
      end

      context 'when AI provider is not configured' do
        let(:ai_provider) { nil }

        it 'raises the exception' do
          expect { service.execute }.to raise_error(Service::CheckFeatureEnabled::FeatureDisabledError, 'AI provider is not configured.')
        end
      end
    end
  end
end
