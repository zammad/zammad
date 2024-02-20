# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Area::Whatsapp, type: :model do
  describe 'validations' do
    let(:another_channel) { create(:whatsapp_channel, phone_number_id:) }
    let(:phone_number_id) { 123_456_780 }

    before { another_channel }

    it 'allows to create another channel with a different phone number' do
      channel = create(:whatsapp_channel)

      expect(channel).to be_persisted
    end

    it 'does not allow to create another channel with the same phone number' do
      channel = build(:whatsapp_channel, phone_number_id:).tap(&:save)

      expect(channel.errors.full_messages).to include(%r{Phone number is already in use})
    end

    it 'allows to edit an existing channel' do
      channel = create(:whatsapp_channel)
      channel.options[:test] = true
      expect { channel.save! }.not_to raise_error
    end

    it 'not applicable to other areas' do
      expect_any_instance_of(Channel).not_to receive(:validate_whatsapp_phone_number)

      create(:google_channel)
    end
  end
end
