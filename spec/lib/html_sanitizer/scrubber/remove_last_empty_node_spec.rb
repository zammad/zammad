# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe HtmlSanitizer::Scrubber::RemoveLastEmptyNode do
  let(:scrubber) { described_class.new }

  describe('#scrubber') do
    subject(:actual) do
      # export with extra options to avoid html indentation
      fragment.scrub!(scrubber)
        .to_html save_with: Nokogiri::XML::Node::SaveOptions::DEFAULT_HTML ^ Nokogiri::XML::Node::SaveOptions::FORMAT
    end

    let(:fragment) { Loofah.fragment(input) }

    context 'when empty b node' do
      let(:input)  { '<div>asd<b></b></div>' }
      let(:target) { '<div>asd</div>' }

      it { is_expected.to eq target }
    end

    context 'when empty div' do
      let(:input)  { '<div>asd<div></div></div>' }
      let(:target) { '<div>asd</div>' }

      it { is_expected.to eq target }
    end

    context 'when not empty div' do
      let(:input)  { '<div>asd<div>qwe</div></div>' }
      let(:target) { '<div>asd<div>qwe</div></div>' }

      it { is_expected.to eq target }
    end

    context 'when tag has another tag' do
      let(:input)  { '<tag>asd<another-tag></another-tag></tag>' }
      let(:target) { '<tag>asd<another-tag></another-tag></tag>' }

      it { is_expected.to eq target }
    end

    context 'when tag has same tag' do
      let(:input)  { '<tag><tag></tag></tag>' }
      let(:target) { '<tag></tag>' }

      it { is_expected.to eq target }
    end

    context 'when tag has same tag with attributes' do
      let(:input)  { '<tag><tag attr="true"></tag></tag>' }
      let(:target) { '<tag attr="true"></tag>' }

      it { is_expected.to eq target }
    end
  end
end
