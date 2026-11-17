# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe EmailUrgency do
  describe '.parse' do
    # RFC 2156 section 5.3.4, registered in RFC 4021 section 2.1.52
    context 'with the standardized Importance header' do
      it 'reads high' do
        expect(described_class.parse({ 'importance' => 'high' })).to eq(EmailUrgency::HIGH)
      end

      it 'reads normal' do
        expect(described_class.parse({ 'importance' => 'Normal' })).to eq(EmailUrgency::NORMAL)
      end

      it 'reads low' do
        expect(described_class.parse({ 'importance' => ' LOW ' })).to eq(EmailUrgency::LOW)
      end

      it 'ignores a value outside of the RFC' do
        expect(described_class.parse({ 'importance' => 'very important' })).to be_nil
      end
    end

    # RFC 2156 section 5.3.6, registered in RFC 4021 section 2.1.54
    context 'with the standardized Priority header' do
      it 'maps urgent to high' do
        expect(described_class.parse({ 'priority' => 'urgent' })).to eq(EmailUrgency::HIGH)
      end

      it 'maps non-urgent to low' do
        expect(described_class.parse({ 'priority' => 'non-urgent' })).to eq(EmailUrgency::LOW)
      end

      it 'maps normal to normal' do
        expect(described_class.parse({ 'priority' => 'normal' })).to eq(EmailUrgency::NORMAL)
      end
    end

    context 'with the non-standardized X-Priority header' do
      it 'maps 1 to high' do
        expect(described_class.parse({ 'x-priority' => '1' })).to eq(EmailUrgency::HIGH)
      end

      it 'maps the Outlook spelling to high' do
        expect(described_class.parse({ 'x-priority' => '1 (Highest)' })).to eq(EmailUrgency::HIGH)
      end

      it 'maps 2 to high' do
        expect(described_class.parse({ 'x-priority' => '2 (High)' })).to eq(EmailUrgency::HIGH)
      end

      it 'maps 3 to normal' do
        expect(described_class.parse({ 'x-priority' => '3 (Normal)' })).to eq(EmailUrgency::NORMAL)
      end

      it 'maps 5 to low' do
        expect(described_class.parse({ 'x-priority' => '5 (Lowest)' })).to eq(EmailUrgency::LOW)
      end

      it 'ignores a value outside of the 1..5 scale' do
        expect(described_class.parse({ 'x-priority' => 'urgent' })).to be_nil
      end

      it 'ignores a number that only starts with a digit of the scale' do
        expect(described_class.parse({ 'x-priority' => '10' })).to be_nil
      end
    end

    context 'with the non-standardized X-MSMail-Priority header' do
      it 'reads high' do
        expect(described_class.parse({ 'x-msmail-priority' => 'High' })).to eq(EmailUrgency::HIGH)
      end
    end

    # [MS-OXCMAIL] section 2.2.3.2.5 defines exactly this 1..5 mapping.
    context 'with the X-Priority values Microsoft specifies' do
      it 'maps the whole scale the way Exchange does' do
        expect(%w[1 2 3 4 5].index_with { |value| described_class.parse({ 'x-priority' => value }) })
          .to eq('1' => EmailUrgency::HIGH, '2' => EmailUrgency::HIGH, '3' => EmailUrgency::NORMAL, '4' => EmailUrgency::LOW, '5' => EmailUrgency::LOW)
      end
    end

    context 'with several headers present' do
      it 'prefers the standardized Importance over the vendor headers' do
        expect(described_class.parse({ 'importance' => 'low', 'x-priority' => '1', 'x-msmail-priority' => 'High' })).to eq(EmailUrgency::LOW)
      end

      it 'does not fall back to the other headers when Importance is unrecognized' do
        expect(described_class.parse({ 'importance' => 'very important', 'priority' => 'urgent', 'x-priority' => '1' })).to be_nil
      end

      it 'prefers the standardized Priority over the vendor headers' do
        expect(described_class.parse({ 'priority' => 'urgent', 'x-priority' => '5' })).to eq(EmailUrgency::HIGH)
      end

      it 'falls back to the vendor headers when the standardized ones are unusable' do
        expect(described_class.parse({ 'importance' => '', 'priority' => 'whatever', 'x-priority' => '1 (Highest)' })).to eq(EmailUrgency::HIGH)
      end
    end

    it 'returns nil when the sender stated no urgency' do
      expect(described_class.parse({ 'subject' => 'no urgency here' })).to be_nil
    end
  end
end
