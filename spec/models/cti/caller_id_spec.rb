require 'rails_helper'

RSpec.describe Cti::CallerId do

  describe 'extract_numbers' do
    it { expect(described_class.extract_numbers("some text\ntest 123")).to eq [] }
    it { expect(described_class.extract_numbers('Lorem ipsum dolor sit amet, consectetuer +49 (0) 30 60 00 00 00-0 adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem. Nulla consequat massa quis enim. Donec pede justo, fringilla vel.')).to eq ['4930600000000'] }
    it { expect(described_class.extract_numbers("GS Oberalteich\nTelefon  09422 1000 Telefax 09422 805000\nE-Mail:  ")).to eq %w(4994221000 499422805000) }
    it { expect(described_class.extract_numbers('Tel +41 81 288 63 93 / +41 76 346 72 14 ...')).to eq %w(41812886393 41763467214) }
    it { expect(described_class.extract_numbers("P: +1 (949) 431 0000\nF: +1 (949) 431 0001\nW: http://znuny")).to eq %w(19494310000 19494310001) }
  end

  describe 'normalize_number' do
    # can be anything
    it { expect(described_class.normalize_number('5754321')).to eq '5754321' }
    it { expect(described_class.normalize_number('622 32281')).to eq '62232281' }
    it { expect(described_class.normalize_number('0049 1234 123456789')).to eq '491234123456789' }
    it { expect(described_class.normalize_number('022 1234567')).to eq '49221234567' }
    it { expect(described_class.normalize_number('0271233211')).to eq '49271233211' }
    it { expect(described_class.normalize_number('021-233-9123')).to eq '49212339123' }
    it { expect(described_class.normalize_number('09 123 32112')).to eq '49912332112' }
    it { expect(described_class.normalize_number('021 2331231')).to eq '49212331231' }
    it { expect(described_class.normalize_number('021 321123123')).to eq '4921321123123' }
    it { expect(described_class.normalize_number('0150 12345678')).to eq '4915012345678' }
    it { expect(described_class.normalize_number('092213212')).to eq '4992213212' }
    it { expect(described_class.normalize_number('(09)1234321')).to eq '4991234321' }
    it { expect(described_class.normalize_number('+49 30 53 00 00 000')).to eq '4930530000000' }
    it { expect(described_class.normalize_number('+49 160 0000000')).to eq '491600000000' }
    it { expect(described_class.normalize_number('+49 (0) 30 60 00 00 00-0')).to eq '4930600000000' }
    it { expect(described_class.normalize_number('0043 (0) 30 60 00 00 00-0')).to eq '4330600000000' }
    it { expect(described_class.normalize_number('0043 30 60 00 00 00-0')).to eq '4330600000000' }
    it { expect(described_class.normalize_number('1-888-407-4747')).to eq '18884074747' }
  end
end
