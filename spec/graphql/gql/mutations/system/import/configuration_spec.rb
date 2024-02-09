# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::System::Import::Configuration, type: :graphql do
  context 'when validation system import configuration' do
    let(:mutation) do
      <<~MUTATION
        mutation systemImportConfiguration($configuration: SystemImportConfigurationInput!) {
          systemImportConfiguration(configuration: $configuration) {
            success
            errors {
              message
              field
            }
          }
        }
      MUTATION
    end

    context 'with valid configuration' do
      let(:variables) do
        {
          configuration: {
            url:    'https://ticket.freshdesk.com',
            secret: 'freshdesk_api_token',
            source: 'freshdesk',
          }
        }
      end

      it 'succeeds' do
        mock = Service::System::Import::ApplyFreshdeskConfiguration
        allow_any_instance_of(mock).to receive(:execute).and_return(true)

        gql.execute(mutation, variables: variables)
        expect(gql.result.data).to include({ 'success' => true })
      end
    end

    shared_examples 'missing required configuration parameter' do
      it 'raises an error' do
        gql.execute(mutation, variables: variables)
        expect { gql.result.data }.to raise_error(RuntimeError, %r{#{parameter}})
      end
    end

    %w[url source].each do |p|
      context "when no #{p} is provided" do
        let(:variables) do
          config = {
            configuration: {
              url:    'https://ticket.otrs.com',
              source: 'otrs'
            }
          }
          config[:configuration].delete(p.to_sym)

          config
        end

        let(:parameter) { p }

        it_behaves_like 'missing required configuration parameter'
      end
    end

    context 'when invalid url is provided' do
      let(:variables) do
        {
          configuration: {
            url:    'gopher://ticket.otrs.com',
            source: 'otrs'
          }
        }
      end

      it 'raises an error' do
        gql.execute(mutation, variables: variables)
        expect { gql.result.data }.to raise_error(RuntimeError, %r{URI scheme must be HTTP or HTTPS})
      end
    end

    context 'when url is not reachable' do
      let(:variables) do
        {
          configuration: {
            url:    'https://ticket.freshdesk.com',
            secret: 'freshdesk_api_token',
            source: 'freshdesk'
          }
        }
      end

      it 'returns an error' do
        mock = Service::System::Import::ApplyFreshdeskConfiguration
        error = Service::System::Import::ApplyFreshdeskConfiguration::UnreachableError
        allow_any_instance_of(mock).to receive(:reachable!).and_raise(error, 'The hostname could not be found.')

        gql.execute(mutation, variables: variables)
        expect(gql.result.data).to include({ 'errors' => [{ 'message' => 'The hostname could not be found.', 'field' => 'url' }] })
      end
    end

    context 'when url is inaccessible' do
      let(:variables) do
        {
          configuration: {
            url:      'https://ticket.zendesk.com',
            username: 'zendesk',
            secret:   'zendesk_api_token',
            source:   'zendesk'
          }
        }
      end

      it 'returns an error' do
        mock = Service::System::Import::ApplyZendeskConfiguration
        error = Service::System::Import::ApplyZendeskConfiguration::InaccessibleError
        allow_any_instance_of(mock).to receive(:reachable!).and_return(nil)
        allow_any_instance_of(mock).to receive(:accessible!).and_raise(error, 'The provided credentials are invalid.')

        gql.execute(mutation, variables: variables)
        expect(gql.result.data).to include({
                                             'errors' => [
                                               { 'message' => 'The provided credentials are invalid.', 'field' => 'secret' },
                                               { 'message' => 'The provided credentials are invalid.', 'field' => 'username' }
                                             ]
                                           })
      end
    end
  end
end
