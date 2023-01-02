# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe HtmlSanitizer::Scrubber::ImageSize do
  let(:scrubber) { described_class.new }

  describe('#scrubber') do
    subject(:actual) { fragment.scrub!(scrubber).to_html }

    let(:fragment) { Loofah.fragment(input) }

    context 'when image' do
      let(:input)  { '<img src="...">' }
      let(:target) { '<img src="..." style="max-width:100%;">' }

      it { is_expected.to eq target }
    end

    context 'when not image' do
      let(:input)  { '<script src="..."></script>' }
      let(:target) { '<script src="..."></script>' }

      it { is_expected.to eq target }
    end

    context 'when does not have source' do
      let(:input)  { '<img>' }
      let(:target) { '<img>' }

      it { is_expected.to eq target }
    end
  end

  describe '#build_style' do
    it 'sets max width' do
      input = ''

      expect(scrubber.send(:build_style, input)).to eq 'max-width:100%;'
    end

    it 'copies old attributes' do
      input = 'attr:value;another:value;'

      expect(scrubber.send(:build_style, input)).to eq 'max-width:100%;attr:value;another:value;'
    end

    it 'renames height to max-height' do
      input = ' height: 20px'

      expect(scrubber.send(:build_style, input)).to eq 'max-width:100%;max-height: 20px;'
    end
  end
end
