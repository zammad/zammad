# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# What adding the first admin does is covered by spec/services/service/user/add_first_admin_spec.rb —
#   this covers the GraphQL surface only: how the service's errors reach the client, and the payload.
RSpec.describe Gql::Mutations::User::AddFirstAdmin, :aggregate_failures, set_up: false, type: :request do
  context 'when adding the first admin user' do
    let(:query) do
      <<~QUERY
        mutation userAddFirstAdmin($input: UserSignupInput!) {
          userAddFirstAdmin(input: $input) {
            session {
              id
              afterAuth {
                type
                data
              }
            }
            errors {
              message
              messagePlaceholder
              field
            }
          }
        }
      QUERY
    end

    let(:variables) do
      {
        input: {
          email:     'bender@futurama.fiction',
          firstname: 'Bender',
          lastname:  'Rodríguez',
          password:  'IloveBender1337'
        }
      }
    end

    let(:headers) do
      {
        'X-Browser-Fingerprint' => 'some-fingerprint',
      }
    end

    let(:graphql_response) do
      post '/graphql', params: { query: query, variables: variables }, headers: headers, as: :json
      json_response
    end

    before do
      allow(Calendar).to receive(:init_setup)
      allow(TextModule).to receive(:load)
      Setting.set('system_init_done', false)
    end

    context 'with an empty system' do
      it 'returns the session of the new user' do
        expect(graphql_response['data']['userAddFirstAdmin']).to include({ 'session' => include({ 'id' => a_kind_of(String) }), 'errors' => nil })
        expect(controller.session[:user_id]).to eq(User.find_by(email: 'bender@futurama.fiction').id)
      end
    end

    context 'without an email address' do
      let(:variables) do
        {
          input: {
            email:     '',
            firstname: 'Bender',
            lastname:  'Rodríguez',
            password:  'IloveBender1337'
          }
        }
      end

      it 'fails with an error' do
        expect(graphql_response['errors'].first['message']).to eq("The required attribute 'email' is missing.")
      end
    end

    context 'with a short password' do
      let(:variables) do
        {
          input: {
            email:     'bender@futurama.fiction',
            firstname: 'Bender',
            lastname:  'Rodríguez',
            password:  'brBR1234',
          }
        }
      end

      it 'fails with an error' do
        expect(graphql_response['data']['userAddFirstAdmin']['errors']).to eq([
                                                                                {
                                                                                  'message'            => 'Invalid password, it must be at least %s characters long!',
                                                                                  'messagePlaceholder' => ['10'],
                                                                                  'field'              => 'password',
                                                                                },
                                                                              ])
      end
    end

    context 'when system has already been configured' do
      before do
        Setting.set('system_init_done', true)
        create(:admin)
      end

      it 'fails with an error' do
        expect(graphql_response['data']['userAddFirstAdmin']['errors']).to eq([
                                                                                {
                                                                                  'message'            => 'This system has already been configured and an administrator account exists.',
                                                                                  'messagePlaceholder' => nil,
                                                                                  'field'              => nil,
                                                                                },
                                                                              ])
      end
    end
  end
end
