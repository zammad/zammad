# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe HtmlSanitizer::Scrubber::Cleanup do
  let(:scrubber) { described_class.new }

  describe('#scrubber') do
    subject(:actual) do
      # export with extra options to avoid html indentation
      fragment.scrub!(scrubber)
        .to_html save_with: Nokogiri::XML::Node::SaveOptions::DEFAULT_HTML ^ Nokogiri::XML::Node::SaveOptions::FORMAT
    end

    let(:fragment) { Loofah.fragment(input) }

    context 'when extra spaces' do
      let(:input)  { "<div> \n </div>" }
      let(:target) { '<div> </div>' }

      it { is_expected.to eq target }
    end

    context 'when extra spaces in preformatted tags' do
      let(:input)  { "<code> \n </code>" }
      let(:target) { "<code> \n </code>" }

      it { is_expected.to eq target }
    end

    context 'when has extra spaces but no siblings' do
      let(:input)  { ' content ' }
      let(:target) { ' content ' }

      it { is_expected.to eq target }
    end

    context 'when div has extra spaces' do
      let(:input)  { '<div>test</div><div> content </div>' }
      let(:target) { '<div>test</div><div>content</div>' }

      it { is_expected.to eq target }
    end

    context 'when span has extra spaces' do
      let(:input)  { '<div>test</div><span> content </span>' }
      let(:target) { '<div>test</div><span> content </span>' }

      it { is_expected.to eq target }
    end

    context 'when has previous' do
      let(:input)  { '<div>test</div> content ' }
      let(:target) { '<div>test</div>content' }

      it { is_expected.to eq target }
    end

    context 'when has next div' do
      let(:input)  { '<div> content <div>test</div></div>' }
      let(:target) { '<div>content<div>test</div></div>' }

      it { is_expected.to eq target }
    end

    context 'when has next span' do
      let(:input)  { '<div> content <span>test</span></div>' }
      let(:target) { '<div> content <span>test</span></div>' }

      it { is_expected.to eq target }
    end

    context 'when p has style with white-space property' do
      let(:input) do
        '<p style="white-space: pre-wrap">Hi!

This is a dummy text for   Zammad   to test multi-line text that is wrapped in a preformatted text block.</p>'
      end
      let(:target) do
        '<p style="white-space: pre-wrap">Hi!

This is a dummy text for Zammad to test multi-line text that is wrapped in a preformatted text block.</p>'
      end

      it { is_expected.to eq target }
    end
  end
end
