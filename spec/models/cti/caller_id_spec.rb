require 'rails_helper'

RSpec.describe Cti::CallerId do
  describe '.extract_numbers' do
    context 'for strings containing arbitrary numbers (<6 digits long)' do
      let(:input) { <<~INPUT }
        some text
        test 123
      INPUT

      it 'returns an empty array' do
        expect(described_class.extract_numbers(input)).to be_empty
      end
    end

    context 'for strings containing a phone number with "(0)" after country code' do
      let(:input) { <<~INPUT }
        Lorem ipsum dolor sit amet, consectetuer +49 (0) 30 60 00 00 00-0 adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem. Nulla consequat massa quis enim. Donec pede justo, fringilla vel.
      INPUT

      it 'returns the number in an array, without the leading "(0)"' do
        expect(described_class.extract_numbers(input)).to eq(['4930600000000'])
      end
    end

    context 'for strings containing a phone number with leading 0 (no country code)' do
      let(:input) { <<~INPUT }
        GS Oberalteich
        Telefon  09422 1000
        E-Mail:
      INPUT

      it 'returns the number in an array, using default country code (49)' do
        expect(described_class.extract_numbers(input)).to eq(['4994221000'])
      end
    end

    context 'for strings containing multiple phone numbers' do
      let(:input) { <<~INPUT }
        Tel +41 81 288 63 93 / +41 76 346 72 14 ...
      INPUT

      it 'returns all numbers in an array' do
        expect(described_class.extract_numbers(input)).to eq(%w[41812886393 41763467214])
      end
    end

    context 'for strings containing US-formatted numbers' do
      let(:input) { <<~INPUT }
        P: +1 (949) 431 0000
        F: +1 (949) 431 0001
        W: http://znuny
      INPUT

      it 'returns the numbers in an array correctly' do
        expect(described_class.extract_numbers(input)).to eq(%w[19494310000 19494310001])
      end
    end
  end

  describe '.normalize_number' do
    it 'does not modify digit-only strings (starting with 1-9)' do
      expect(described_class.normalize_number('5754321')).to eq('5754321')
    end

    it 'strips whitespace' do
      expect(described_class.normalize_number('622 32281')).to eq('62232281')
    end

    it 'strips hyphens' do
      expect(described_class.normalize_number('1-888-407-4747')).to eq('18884074747')
    end

    it 'strips leading pluses' do
      expect(described_class.normalize_number('+49 30 53 00 00 000')).to eq('4930530000000')
      expect(described_class.normalize_number('+49 160 0000000')).to eq('491600000000')
    end

    it 'replaces a single leading zero with the default country code (49)' do
      expect(described_class.normalize_number('092213212')).to eq('4992213212')
      expect(described_class.normalize_number('0271233211')).to eq('49271233211')
      expect(described_class.normalize_number('022 1234567')).to eq('49221234567')
      expect(described_class.normalize_number('09 123 32112')).to eq('49912332112')
      expect(described_class.normalize_number('021 2331231')).to eq('49212331231')
      expect(described_class.normalize_number('021 321123123')).to eq('4921321123123')
      expect(described_class.normalize_number('0150 12345678')).to eq('4915012345678')
      expect(described_class.normalize_number('021-233-9123')).to eq('49212339123')
    end

    it 'strips two leading zeroes' do
      expect(described_class.normalize_number('0049 1234 123456789')).to eq('491234123456789')
      expect(described_class.normalize_number('0043 30 60 00 00 00-0')).to eq('4330600000000')
    end

    it 'strips leading zero from "(0x)" at start of number or after country code' do
      expect(described_class.normalize_number('(09)1234321')).to eq('4991234321')
      expect(described_class.normalize_number('+49 (0) 30 60 00 00 00-0')).to eq('4930600000000')
      expect(described_class.normalize_number('0043 (0) 30 60 00 00 00-0')).to eq('4330600000000')
    end
  end

  describe 'callbacks' do
    subject!(:caller_id) { build(:cti_caller_id, caller_id: phone) }
    let(:phone) { '1234567890' }

    describe 'on creation' do
      it 'adopts CTI Logs from same number (via UpdateCtiLogsByCallerJob)' do
        expect(UpdateCtiLogsByCallerJob).to receive(:perform_later)

        caller_id.save
      end

      it 'splits job into fg and bg (for more responsive UI – see #2057)' do
        expect(UpdateCtiLogsByCallerJob).to receive(:perform_now).with(phone, limit: 20)
        expect(UpdateCtiLogsByCallerJob).to receive(:perform_later).with(phone, limit: 40, offset: 20)

        caller_id.save
      end
    end

    describe 'on destruction' do
      before { caller_id.save }

      it 'orphans CTI Logs from same number (via UpdateCtiLogsByCallerJob)' do
        expect(UpdateCtiLogsByCallerJob).to receive(:perform_later).with(phone)

        caller_id.destroy
      end
    end
  end
end
