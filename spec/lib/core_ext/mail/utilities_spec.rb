# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Mail::Utilities do
  let(:text) { '报价 €1,200 – 请确认' }
  let(:gbk)  { text.encode('GBK').b }

  describe '.pick_encoding' do
    it 'resolves gb2312 to the encoding it names' do
      expect(described_class.pick_encoding('gb2312')).to be(Encoding::GB2312)
    end

    it 'resolves aliases and spellings Ruby does not know', :aggregate_failures do
      {
        Encoding::GB2312  => %w[GB_2312-80 gb-2312 gb2312_80 csGB2312 chinese iso-ir-58 csISO58GB231280],
        Encoding::GB18030 => %w[gb-18030 GB18030-2005],
        Encoding::GBK     => %w[x-gbk windows-936 windows936 ms936 cp-936 csGBK],
      }.each do |encoding, charsets|
        charsets.each { expect(described_class.pick_encoding(it)).to be(encoding) }
      end
    end

    it 'leaves other charsets to the gem' do
      expect(described_class.pick_encoding('ks_c_5601-1987')).to be(Encoding::CP949)
    end
  end

  shared_examples 'decoding GB2312 and GBK as GB18030' do
    subject(:charset_encoder) { described_class.new }

    def decode(bytes, charset)
      charset_encoder.encode(bytes, charset).encode('UTF-8')
    end

    it 'reads the euro sign of code page 936, which GB18030 rejects' do
      expect(decode(gbk, 'gb2312')).to eq(text)
    end

    it 'reads GB18030 four-byte sequences declared as gbk' do
      expect(decode('价 😀'.encode('GB18030').b, 'gbk')).to eq('价 😀')
    end

    it 'reads aliases of GB2312 and GBK', :aggregate_failures do
      %w[GB_2312-80 csGB2312 EUC-CN x-gbk windows-936].each do |charset|
        expect(decode(gbk.dup, charset)).to eq(text)
      end
    end

    it 'replaces other invalid sequences' do
      expect(decode('价'.encode('GBK').b + "\xFF".b, 'gb2312')).to eq('价�')
    end

    it 'returns valid input as it is' do
      valid = '你好'.encode('GBK').b

      expect(charset_encoder.encode(valid, 'gb2312')).to be(valid)
    end

    it 'leaves the bytes of invalid input untouched' do
      bytes = gbk.dup
      charset_encoder.encode(bytes, 'gb2312')

      expect(bytes.b).to eq(gbk)
    end
  end

  describe Mail::Utilities::StrictCharsetEncoder do
    it_behaves_like 'decoding GB2312 and GBK as GB18030'
  end

  describe Mail::Utilities::BestEffortCharsetEncoder do
    it_behaves_like 'decoding GB2312 and GBK as GB18030'
  end

  # regression test for issue 6461
  it 'decodes the euro sign of code page 936 in an encoded word' do
    expect(Mail::Encodings.value_decode("=?gb2312?B?#{[gbk].pack('m0')}?=")).to eq(text)
  end
end
