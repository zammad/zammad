# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe UpdateCtiLogsByCallerJob, type: :job do
  let(:phone)     { '491234567890' }
  let!(:logs)     { create_list(:cti_log, 5, direction: :in, from: phone) }
  let(:log_prefs) { logs.each(&:reload).map { |log| log.preferences[:from] } }

  it 'accepts a phone number' do
    expect { described_class.perform_now(phone) }
      .not_to raise_error
  end

  context 'with no user matching provided phone number' do
    it 'updates Cti::Logs from that number with "preferences" => {}' do
      described_class.perform_now(phone)

      expect(log_prefs).to eq(Array.new(5) { nil })
    end
  end

  context 'with existing user matching provided phone number' do
    before { create(:user, phone: phone) }

    it 'updates Cti::Logs from that number with valid "preferences" hash' do
      described_class.perform_now(phone)

      expect(log_prefs).not_to eq(Array.new(5) { nil })
    end

    # The telephony backend decides the stored format; the caller id is always plain digits.
    context 'when the backend stored the number in another format' do
      let!(:logs) do
        ['+491234567890', '00491234567890', '+49 1234 567890', '01234567890'].map do |from|
          create(:cti_log, direction: :in, from: from)
        end
      end

      it 'updates them all the same' do
        described_class.perform_now(phone)

        expect(log_prefs).to all(be_present)
      end
    end

    context 'when another number only ends in the same digits' do
      let!(:logs) { [create(:cti_log, direction: :in, from: '+33491234567890')] }

      it 'leaves it alone' do
        described_class.perform_now(phone)

        expect(log_prefs).to eq([nil])
      end
    end
  end

  # The national 0 stands for the default country only, so a foreign number has fewer variants.
  context 'with a customer from another country' do
    let(:phone) { '43664123456' }

    before { create(:user, phone: '+43 664 123456') }

    context 'when the backend stored the number in an international format' do
      let!(:logs) do
        ['43664123456', '+43664123456', '0043664123456'].map do |from|
          create(:cti_log, direction: :in, from: from)
        end
      end

      it 'updates them all the same' do
        described_class.perform_now(phone)

        expect(log_prefs).to all(be_present)
      end
    end

    context 'when the backend stored the national format' do
      let!(:logs) { [create(:cti_log, direction: :in, from: '0664123456')] }

      it 'leaves it alone, as the caller id would read it as a default country number' do
        described_class.perform_now(phone)

        expect(log_prefs).to eq([nil])
      end
    end
  end

  context 'with a customer whose country code shares digits with the default country' do
    let(:phone) { '4915112345678' }

    before { create(:user, phone: '+49 151 12345678') }

    context 'when another country ends in the same national digits' do
      let!(:logs) { [create(:cti_log, direction: :in, from: '+4315112345678')] }

      it 'leaves it alone' do
        described_class.perform_now(phone)

        expect(log_prefs).to eq([nil])
      end
    end
  end
end
