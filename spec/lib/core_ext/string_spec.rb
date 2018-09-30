require 'rails_helper'

RSpec.describe String do
  describe '#utf8_encode' do
    context 'on valid, UTF-8-encoded strings' do
      let(:subject) { 'hello' }

      it 'returns an identical copy' do
        expect(subject.utf8_encode).to eq(subject)
        expect(subject.utf8_encode.encoding).to be(subject.encoding)
        expect(subject.utf8_encode).not_to be(subject)
      end

      context 'which are incorrectly set to other, technically valid encodings' do
        let(:subject) { 'ö'.force_encoding('tis-620') }

        it 'sets input encoding to UTF-8 instead of attempting conversion' do
          expect(subject.utf8_encode).to eq(subject.force_encoding('utf-8'))
        end
      end
    end

    context 'on strings in other encodings' do
      let(:subject) { original_string.encode(input_encoding) }

      context 'with no from: option' do
        let(:original_string) { 'Tschüss!' }
        let(:input_encoding) { Encoding::ISO_8859_2 }

        it 'detects the input encoding' do
          expect(subject.utf8_encode).to eq(original_string)
        end
      end

      context 'with a valid from: option' do
        let(:original_string) { 'Tschüss!' }
        let(:input_encoding) { Encoding::ISO_8859_2 }

        it 'uses the specified input encoding' do
          expect(subject.utf8_encode(from: 'iso-8859-2')).to eq(original_string)
        end

        it 'uses any valid input encoding, even if not correct' do
          expect(subject.utf8_encode(from: 'gb18030')).to eq('Tsch黶s!')
        end
      end

      context 'with an invalid from: option' do
        let(:original_string) { '―陈志' }
        let(:input_encoding) { Encoding::GB18030 }

        it 'does not try it' do
          expect { subject.encode('utf-8', 'gb2312') }
            .to raise_error(Encoding::InvalidByteSequenceError)

          expect { subject.utf8_encode(from: 'gb2312') }
            .not_to raise_error(Encoding::InvalidByteSequenceError)
        end

        it 'uses the detected input encoding instead' do
          expect(subject.utf8_encode(from: 'gb2312')).to eq(original_string)
        end
      end
    end
  end
end
