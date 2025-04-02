# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Channel::Whatsapp::Update, current_user_id: 1 do
  subject(:service) { described_class.new(params:, channel_id: channel.id) }

  shared_examples 'raising an error' do |klass, message|
    it 'raises an error' do
      expect { service.execute }.to raise_error(klass, message)
    end
  end

  describe '#execute' do
    let(:channel)         { create(:whatsapp_channel) }
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

      before do
        allow_any_instance_of(Whatsapp::Account::PhoneNumbers).to receive(:get).and_return(phone_number_info)
      end

      it 'updates the existing channel' do
        expect { service.execute }
          .to change { channel.reload.options['business_id'] }.to(params[:business_id])
          .and change { channel.options['access_token'] }.to(params[:access_token])
          .and change { channel.options['app_secret'] }.to(params[:app_secret])
          .and change { channel.options['welcome'] }.to(params[:welcome])
          .and change { channel.options['name'] }.to(phone_number_info[:name])
          .and change { channel.options['phone_number'] }.to(phone_number_info[:phone_number])
          .and not_change { channel.options['adapter'] }
          .and not_change { channel.options['callback_url_uuid'] }
          .and not_change { channel.options['verify_token'] }
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
