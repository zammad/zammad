# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Channel::Whatsapp::Preload do
  subject(:service) { described_class.new(**params) }

  describe '#execute' do
    context 'with all params' do
      let(:params) do
        {
          business_id:  Faker::Number.unique.number(digits: 15),
          access_token: Faker::Omniauth.unique.facebook[:credentials][:token],
        }
      end

      let(:internal_response) do
        {
          Faker::Number.unique.number(digits: 15) => format('%{name} (%{number})', name: Faker::Name.unique.name, number: Faker::PhoneNumber.unique.cell_phone_with_country_code),
          Faker::Number.unique.number(digits: 15) => format('%{name} (%{number})', name: Faker::Name.unique.name, number: Faker::PhoneNumber.unique.cell_phone_with_country_code),
          Faker::Number.unique.number(digits: 15) => format('%{name} (%{number})', name: Faker::Name.unique.name, number: Faker::PhoneNumber.unique.cell_phone_with_country_code),
        }
      end

      before do
        allow_any_instance_of(Whatsapp::Account::PhoneNumbers).to receive(:all).and_return(internal_response)
      end

      it 'returns phone number options' do
        expect(service.execute).to eq(phone_numbers: internal_response.map { |value, label| { value:, label: } })
      end
    end
  end
end
