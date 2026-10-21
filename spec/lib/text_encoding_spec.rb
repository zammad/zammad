# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TextEncoding, :aggregate_failures do
  describe '.utf8_encode' do
    context 'with valid, UTF-8-encoded strings' do
      subject(:string) { 'hello' }

      it 'returns an identical copy' do
        expect(described_class.utf8_encode(string)).to eq(string)
        expect(described_class.utf8_encode(string).encoding).to be(string.encoding)
        expect(described_class.utf8_encode(string)).not_to be(string)
      end

      context 'when incorrectly set to other, technically valid encodings' do
        subject(:string) { String.new('ö', encoding: 'tis-620') }

        it 'sets input encoding to UTF-8 instead of attempting conversion' do
          expect(described_class.utf8_encode(string)).to eq(string.dup.force_encoding('utf-8'))
        end
      end
    end

    context 'with values that are not strings' do
      it 'coerces them with to_s' do
        expect(described_class.utf8_encode(:hello)).to eq('hello')
        expect(described_class.utf8_encode(42)).to eq('42')
      end

      it 'returns an empty string for nil' do
        expect(described_class.utf8_encode(nil)).to eq('')
      end

      it 'applies the options to the coerced string' do
        object = Struct.new(:value).new('Tschüss!'.encode(Encoding::ISO_8859_2))
        allow(object).to receive(:to_s).and_return(object.value)

        expect(described_class.utf8_encode(object, from: 'iso-8859-2')).to eq('Tschüss!')
      end
    end

    context 'with strings in other encodings' do
      subject(:string) { original_string.encode(input_encoding) }

      context 'with no from: option' do
        let(:original_string) { 'Tschüss!' }
        let(:input_encoding)  { Encoding::ISO_8859_2 }

        it 'detects the input encoding' do
          expect(described_class.utf8_encode(string)).to eq(original_string)
        end
      end

      # Code page 936 writes the euro sign as the single byte 0x80. The detection
      # reports it as GB18030, which rejects that byte in Ruby.
      context 'with code page 936 content that only the detection can place' do
        subject(:string) { original_string.encode(input_encoding).b }

        let(:original_string) { '欧元报价：€1,200 – 请确认。谢谢' }
        let(:input_encoding)  { Encoding::GBK }

        it 'decodes it without a from: option' do
          expect(CharDet.detect(string)['encoding']).to eq('GB18030')
          expect(described_class.utf8_encode(string)).to eq(original_string)
        end

        it 'decodes it with a from: option nobody resolves' do
          expect(described_class.utf8_encode(string, from: 'x-gbk')).to eq(original_string)
        end
      end

      context 'with a valid from: option' do
        let(:original_string) { 'Tschüss!' }
        let(:input_encoding) { Encoding::ISO_8859_2 }

        it 'uses the specified input encoding' do
          expect(described_class.utf8_encode(string, from: 'iso-8859-2')).to eq(original_string)
        end

        it 'uses any valid input encoding, even if not correct' do
          expect(described_class.utf8_encode(string, from: 'gb18030')).to eq('Tsch黶s!')
        end
      end

      context 'with an invalid from: option' do
        # Binary, like the mail parser hands it over - otherwise the encoding of
        # the string itself would be a viable candidate and mask the detection.
        subject(:string) { original_string.encode(input_encoding).b }

        let(:original_string) { 'Tschüss!' }
        let(:input_encoding)  { Encoding::ISO_8859_2 }

        it 'does not try it' do
          expect { string.encode('utf-8', 'us-ascii') }
            .to raise_error(Encoding::InvalidByteSequenceError)

          expect { described_class.utf8_encode(string, from: 'us-ascii') }
            .not_to raise_error
        end

        it 'uses the detected input encoding instead' do
          expect(described_class.utf8_encode(string, from: 'us-ascii')).to eq(original_string)
        end
      end

      # regression test for issue 6461
      context 'with a from: option that mailers use for a superset of it' do
        subject(:string) { original_string.encode(input_encoding).b }

        # The en dash is undefined in GB2312, Outlook sends it as GBK anyway.
        let(:original_string) { 'Hong Kong (HKG) – Zurich (ZRH) – Tel Aviv (TLV)' }
        let(:input_encoding)  { Encoding::GBK }

        it 'decodes GBK content declared as gb2312' do
          expect { string.encode('utf-8', 'gb2312') }
            .to raise_error(Encoding::InvalidByteSequenceError)

          expect(described_class.utf8_encode(string, from: 'gb2312')).to eq(original_string)
        end

        # Code page 936 writes the euro sign as the single byte 0x80, which
        # GB18030 rejects.
        context 'with a euro sign' do
          let(:original_string) { '欧元报价：€1,200 – 请确认。谢谢' }

          it 'decodes it declared as gb2312' do
            expect(described_class.utf8_encode(string, from: 'gb2312')).to eq(original_string)
          end

          it 'decodes it declared as gbk' do
            expect(described_class.utf8_encode(string, from: 'gbk')).to eq(original_string)
          end

          # English text keeps the detection from placing it instead.
          context 'with English text' do
            let(:original_string) { 'Hong Kong (HKG) – Zurich (ZRH), €1,200' }

            it 'decodes it declared as gb18030' do
              expect(described_class.utf8_encode(string, from: 'gb18030')).to eq(original_string)
            end

            it 'decodes it declared with an alias of GB2312 or GBK' do
              %w[GB_2312-80 gb_2312 gb2312_80 csGB2312 chinese iso-ir-58 csISO58GB231280 EUC-CN x-gbk ms936 windows-936 cp-936 csGBK gb-18030].each do |charset|
                expect(described_class.utf8_encode(string, from: charset)).to eq(original_string)
              end
            end
          end
        end

        context 'with GB18030 content' do
          let(:original_string) { 'Hong Kong – Zurich, €1,200 😀 𠀀' }
          let(:input_encoding)  { Encoding::GB18030 }

          it 'decodes it declared as gb2312' do
            expect(string.dup.force_encoding('GBK')).not_to be_valid_encoding

            expect(described_class.utf8_encode(string, from: 'gb2312')).to eq(original_string)
          end

          it 'decodes it declared as gbk' do
            expect(described_class.utf8_encode(string, from: 'gbk')).to eq(original_string)
          end

          it 'decodes it next to a euro sign of code page 936' do
            mixed = 'Hong Kong – Zurich, €1,200'.encode('GBK').b + ' 😀'.encode('GB18030').b

            expect(described_class.utf8_encode(mixed, from: 'gb2312')).to eq('Hong Kong – Zurich, €1,200 😀')
          end
        end

        context 'with GB2312 content' do
          let(:original_string) { '你好，世界' }
          let(:input_encoding)  { Encoding::GB2312 }

          it 'decodes it unchanged' do
            expect(described_class.utf8_encode(string, from: 'gb2312')).to eq(original_string)
          end
        end

        # The declared charset wins, as for any other label: byte pairs that GB18030
        # maps to characters decode as wrong ones. Only a pair it maps to private
        # use, like the one of 航 here, hands the content over to the detection.
        context 'with content in another multibyte charset that GB18030 reads as private use' do
          let(:original_string) { '請確認航班' }
          let(:input_encoding)  { Encoding::Big5 }

          it 'falls back to the detected encoding' do
            expect(string.encode('utf-8', 'gb18030')).to match(%r{\p{Co}})

            %w[gb2312 gbk gb18030].each do |charset|
              expect(described_class.utf8_encode(string, from: charset)).to eq(original_string)
            end
          end
        end
      end

      # regression test for issue 6340
      context 'with a from: option that Ruby cannot resolve' do
        # Binary, like the mail parser hands it over - otherwise the encoding of
        # the string itself would be a viable candidate and mask the fallback.
        subject(:string) { original_string.encode(input_encoding).b }

        let(:original_string) { 'Добрый день' }
        let(:input_encoding)  { Encoding::CP949 }

        it 'resolves the charset label via the mail gem' do
          expect { Encoding.find('ks_c_5601-1987') }
            .to raise_error(ArgumentError)

          expect(described_class.utf8_encode(string, from: 'ks_c_5601-1987')).to eq(original_string)
        end

        it 'falls back to encoding detection if the mail gem cannot resolve it either' do
          expect(described_class.utf8_encode(string, from: 'totally-unknown-charset'))
            .to eq(described_class.utf8_encode(string))
        end
      end
    end

    context 'when no valid encoding can be found' do
      # Bytes that are undefined in windows-1252, which makes the detection
      # return nothing and leaves no viable encoding to try.
      subject(:string) { "\x81\x8D\x8F\x90\x9D".b }

      it 'raises without a fallback' do
        expect { described_class.utf8_encode(string) }
          .to raise_error(EncodingError, 'could not find a valid input encoding')
      end

      it 'returns binary with fallback: :output_to_binary' do
        expect(described_class.utf8_encode(string, fallback: :output_to_binary).encoding)
          .to be(Encoding::ASCII_8BIT)
      end

      it 'replaces invalid byte sequences with fallback: :read_as_sanitized_binary' do
        expect(described_class.utf8_encode(string, fallback: :read_as_sanitized_binary))
          .to eq('?????')
      end
    end

    context 'when the detection returns a charset that Ruby cannot resolve' do
      subject(:string) { "\x81\x8D\x8F\x90\x9D".b }

      before { allow(CharDet).to receive(:detect).and_return({ 'encoding' => 'HZ-GB-2312' }) }

      it 'skips it instead of raising' do
        expect { described_class.utf8_encode(string) }
          .to raise_error(EncodingError, 'could not find a valid input encoding')
      end

      it 'still applies the fallback' do
        expect(described_class.utf8_encode(string, fallback: :read_as_sanitized_binary))
          .to eq('?????')
      end
    end

    context 'when the given string is frozen' do
      subject(:string) { 'Tschüss!'.encode(Encoding::ISO_8859_2).freeze }

      it 'does not modify it' do
        expect { described_class.utf8_encode(string) }.not_to change(string, :encoding)
      end

      it 'returns the converted copy' do
        expect(described_class.utf8_encode(string)).to eq('Tschüss!')
      end
    end

    context 'with large strings (performance)' do
      subject(:string) { original_string.encode(input_encoding) }

      context 'with utf8_encode in iso-8859-1' do
        let(:original_string) { 'äöü0' * 999_999 }
        let(:input_encoding) { Encoding::ISO_8859_1 }

        it 'detects the input encoding' do
          result = nil

          expect { result = described_class.utf8_encode(string, from: 'iso-8859-1') }.to take_less_cpu_time_than(1)
          expect(result).to eq(original_string)
        end
      end

      context 'with utf8_encode in utf-8' do
        let(:original_string) { 'äöü0' * 999_999 }
        let(:input_encoding) { Encoding::UTF_8 }

        it 'detects the input encoding' do
          result = nil

          expect { result = described_class.utf8_encode(string, from: 'utf-8') }.to take_less_cpu_time_than(1)
          expect(result).to eq(original_string)
        end
      end

      context 'with utf8_encode in iso-8859-1 and charset detection' do
        let(:original_string) { 'äöü0' * 199_999 }
        let(:input_encoding) { Encoding::ISO_8859_1 }

        it 'detects the input encoding' do
          result = nil

          expect { result = described_class.utf8_encode(string, from: 'utf-8') }.to take_less_cpu_time_than(18)
          expect(result).to eq(original_string)
        end
      end
    end
  end
end
