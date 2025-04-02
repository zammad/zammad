# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Ticket::ExternalReferences::IssueTracker::TicketList, integration: true, required_envs: %w[GITHUB_ENDPOINT GITHUB_ISSUE_LINK GITHUB_APITOKEN] do
  subject(:service) { described_class.new(ticket:, type:) }

  context 'when GitHub is used' do
    let(:type)        { 'github' }
    let(:ticket)      { create(:ticket) }
    let(:issue_links) { [ENV['GITHUB_ISSUE_LINK']] }

    shared_examples 'raising an error' do |klass, message|
      it 'raises an error' do
        expect { service.execute }.to raise_error(klass, include(message))
      end
    end

    describe '#execute' do
      context 'when github integration is not active' do
        it_behaves_like 'raising an error', Service::CheckFeatureEnabled::FeatureDisabledError, 'This feature is not enabled.'
      end

      context 'when github integration is active' do
        let(:expected_issues) do
          [
            {
              id:         '1575',
              title:      'GitHub integration',
              url:        ENV['GITHUB_ISSUE_LINK'],
              icon_state: 'closed',
              milestone:  '4.0',
              assignees:  ['Thorsten'],
              labels:     [
                {
                  color:      '#84b6eb',
                  text_color: '#000000',
                  title:      'enhancement'
                },
                {
                  color:      '#bfdadc',
                  text_color: '#000000',
                  title:      'integration'
                }
              ],
            }
          ]
        end

        before do
          Setting.set('github_integration', true)
          Setting.set('github_config', { 'endpoint' => ENV['GITHUB_ENDPOINT'], 'api_token' => ENV['GITHUB_APITOKEN'] })
        end

        context 'with ticket with issues links' do
          before do
            ticket.preferences[:github] = { issue_links: }
            ticket.save!
          end

          it 'returns a list of issues' do
            expect(service.execute).to eq(expected_issues)
          end
        end

        context 'with empty issue links' do
          let(:expected_issues) { [] }

          it 'returns empty issue list' do
            expect(service.execute).to eq(expected_issues)
          end
        end
      end
    end
  end
end
