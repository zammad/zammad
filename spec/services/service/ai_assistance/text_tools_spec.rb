# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AIAssistance::TextTools do
  subject(:service_result) { described_class.with_current_user(user).execute(input:, text_tool:, template_render_context:) }

  let(:user)                    { create(:agent) }
  let(:text_tool)               { create(:ai_text_tool) }
  let(:template_render_context) { {} }
  let(:input)                   { 'Hello, wrld!' }

  context 'when text tool service is used' do
    before do
      setup_ai_provider('open_ai')
      Setting.set('ai_assistance_text_tools', true)

      allow_any_instance_of(AI::Service::TextTool)
        .to receive(:execute)
        .and_return(expected_output)
    end

    let(:expected_output) { Struct.new(:content, :stored_result, :fresh).new(content: 'Hello, world!', stored_result: nil, fresh: false) }

    describe '#execute' do
      context 'when valid text tool is used' do
        it 'returns the corrected input' do
          expect(service_result).to eq(expected_output)
        end
      end

      context 'when template variables are used in the text tool instruction' do
        let(:customer)     { create(:customer, firstname: 'John', lastname: 'Doe') }
        let(:user)         { create(:user, firstname: 'Jane', lastname: 'Smith') }
        let(:group)        { create(:group, name: 'Support Team') }
        let(:ticket)       { create(:ticket, customer: customer, group: group, title: 'Test Ticket') }
        let(:organization) { create(:organization, name: 'Test Org') }
        let(:template_render_context) do
          {
            ticket:       ticket,
            customer:     customer,
            user:         user,
            group:        group,
            organization: organization,
          }
        end
        let(:text_tool) { create(:ai_text_tool, instruction: 't:#{ticket.customer.fullname} | c:#{customer.fullname} | u:#{user.fullname} | g:#{group.name} | o:#{organization.name} | m:#{missing.nonexisting}') } # rubocop:disable Lint/InterpolationCheck

        let(:expected_content) { "t:#{ticket.customer.fullname} | c:#{customer.fullname} | u:#{user.fullname} | g:#{group.name} | o:#{organization.name} | m:-" }

        it 'renders all template variables in the instruction' do
          ai_service_spy = instance_spy(AI::Service::TextTool)
          allow(AI::Service::TextTool).to receive(:new).and_return(ai_service_spy)
          allow(ai_service_spy).to receive(:execute).and_return(expected_output)

          service_result

          expect(AI::Service::TextTool).to have_received(:new).with(hash_including(
                                                                      context_data: hash_including(
                                                                        instruction: expected_content
                                                                      )
                                                                    ))
        end
      end

      context 'when an invalid text tool is used' do
        let(:text_tool) { 'i_am_a_string' }

        it 'raises an error' do
          expect { service_result }.to raise_error(ArgumentError, 'AI assistance text tool is invalid.')
        end
      end

      context 'when an inactive text tool is used' do
        let(:text_tool) { create(:ai_text_tool, active: false) }

        it 'raises an error' do
          expect { service_result }.to raise_error(ArgumentError, 'AI assistance text tool is inactive.')
        end
      end
    end
  end
end
