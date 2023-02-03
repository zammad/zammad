# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::AutocompleteSearch::Recipient, authenticated_as: :agent, type: :graphql do
  let(:agent)     { create(:agent) }
  let(:recipient) { create(:customer) }
  let(:query)     do
    <<~QUERY
      query autocompleteSearchRecipient($input: AutocompleteSearchRecipientInput!)  {
        autocompleteSearchRecipient(input: $input) {
          value
          label
          labelPlaceholder
          heading
          headingPlaceholder
          disabled
          icon
        }
      }
    QUERY
  end

  before do
    gql.execute(query, variables: variables)
  end

  shared_examples 'returning expected recipient payload' do |contact:|
    let(:recipient_payload) do
      value = case contact
              when 'phone'
                recipient.phone
              when 'mobile'
                recipient.mobile
              else
                recipient.email
              end

      {
        'value'              => value,
        'label'              => value,
        'labelPlaceholder'   => nil,
        'heading'            => recipient.fullname,
        'headingPlaceholder' => nil,
        'icon'               => nil,
        'disabled'           => nil,
      }
    end

    it 'returns expected recipient payload' do
      expect(gql.result.data).to eq([recipient_payload])
    end
  end

  shared_examples 'returning empty data set' do
    it 'returns empty data set' do
      expect(gql.result.data).to eq([])
    end
  end

  context 'when searching for recipients' do
    let(:variables) { { input: { query: query_string } } }

    context 'with implicit contact' do
      let(:query_string) { recipient.email }

      it_behaves_like 'returning expected recipient payload', contact: 'email'
    end

    context 'with explicit contact' do
      let(:variables)    { { input: { query: query_string, contact: user_contact } } }
      let(:query_string) { recipient.login }

      context 'with email address' do
        let(:user_contact) { 'email' }

        it_behaves_like 'returning expected recipient payload', contact: 'email'
      end

      context 'with phone number' do
        let(:phone_number) do
          Faker::Config.locale = 'de'
          Faker::PhoneNumber.cell_phone_in_e164
        end
        let(:recipient)    { create(:customer, phone: phone_number) }
        let(:user_contact) { 'phone' }

        it_behaves_like 'returning expected recipient payload', contact: 'phone'

        context 'with mobile number' do
          let(:mobile) do
            Faker::Config.locale = 'de'
            Faker::PhoneNumber.cell_phone_in_e164
          end
          let(:recipient) { create(:customer, mobile: phone_number) }

          it_behaves_like 'returning expected recipient payload', contact: 'mobile'
        end
      end

      context 'with multiple phone numbers' do
        let(:phone_number) do
          Faker::Config.locale = 'de'
          Faker::PhoneNumber.cell_phone_in_e164
        end
        let(:mobile_number) do
          Faker::Config.locale = 'de'
          Faker::PhoneNumber.cell_phone_in_e164
        end
        let(:recipient)    { create(:customer, phone: phone_number, mobile: mobile_number) }
        let(:user_contact) { 'phone' }
        let(:recipient_payload) do
          [
            {
              'value'              => mobile_number,
              'label'              => mobile_number,
              'labelPlaceholder'   => nil,
              'heading'            => recipient.fullname,
              'headingPlaceholder' => nil,
              'icon'               => nil,
              'disabled'           => nil,
            },
            {
              'value'              => phone_number,
              'label'              => phone_number,
              'labelPlaceholder'   => nil,
              'heading'            => recipient.fullname,
              'headingPlaceholder' => nil,
              'icon'               => nil,
              'disabled'           => nil,
            },
          ]
        end

        it 'returns expected recipient payload' do
          expect(gql.result.data).to eq(recipient_payload)
        end
      end

      context 'with empty value' do
        let(:user_contact) { 'phone' }

        it_behaves_like 'returning empty data set'
      end
    end
  end
end
