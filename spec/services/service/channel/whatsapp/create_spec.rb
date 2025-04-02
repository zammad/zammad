# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Channel::Whatsapp::Create, :aggregate_failures, current_user_id: 1 do
  subject(:service) { described_class.new(params: params) }

  shared_examples 'raising an error' do |klass, message|
    it 'raises an error' do
      expect { service.execute }.to raise_error(klass, message)
    end
  end

  describe '#execute' do
    let(:phone_number_id) { Faker::Number.unique.number(digits: 15) }

    let(:params) do
      {
        group_id:        1,
        business_id:     Faker::Number.unique.number(digits: 15),
        access_token:    Faker::Omniauth.unique.facebook[:credentials][:token],
        app_secret:      Faker::Crypto.unique.md5,
        phone_number_id:,
        welcome:         Faker::Lorem.unique.sentence,
      }
    end

    context 'with all params' do
      let(:phone_number_info) do
        {
          name:         Faker::Name.unique.name,
          phone_number: Faker::PhoneNumber.unique.cell_phone_with_country_code,
        }
      end

      let(:initial_options) do
        {
          adapter:           'whatsapp',
          callback_url_uuid: SecureRandom.uuid,
          verify_token:      SecureRandom.urlsafe_base64(12),
        }
      end

      before do
        allow_any_instance_of(Whatsapp::Account::PhoneNumbers).to receive(:get).and_return(phone_number_info)
        allow_any_instance_of(described_class).to receive(:initial_options).and_return(initial_options)
      end

      it 'adds a new channel' do
        expect { service.execute }.to change(Channel, :count).by(1)
        expect(Channel.last).to have_attributes(
          group_id: params[:group_id],
          options:  {
            **params.except(:group_id).stringify_keys,
            **phone_number_info.stringify_keys,
            **initial_options.stringify_keys,
          },
        )
      end
    end

    context 'when phone number metadata cannot be retrieved' do
      before do
        allow_any_instance_of(Whatsapp::Account::PhoneNumbers).to receive(:get).and_return(nil)
      end

      it_behaves_like 'raising an error', StandardError, 'Could not fetch WhatsApp phone number details.'
    end
  end
end
