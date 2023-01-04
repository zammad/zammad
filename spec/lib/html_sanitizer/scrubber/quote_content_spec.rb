# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe HtmlSanitizer::Scrubber::QuoteContent do
  let(:scrubber) { described_class.new }

  describe('#scrubber') do
    subject(:actual) do
      # export with extra options to avoid html indentation
      fragment.scrub!(scrubber)
        .to_html save_with: Nokogiri::XML::Node::SaveOptions::DEFAULT_HTML ^ Nokogiri::XML::Node::SaveOptions::FORMAT
    end

    before do
      allow(Rails.application.config)
        .to receive(:html_sanitizer_tags_quote_content)
        .and_return(%w[tag-to-quote])
    end

    let(:fragment) { Loofah.fragment(input) }

    context 'when tag-to-quote div' do
      let(:input)  { '<tag-to-quote><div>&amp;content</div></tag-to-quote>' }
      let(:target) { '&amp;content' }

      it { is_expected.to eq target }
    end

    context 'when div' do
      let(:input)  { '<div>&amp;content</div>' }
      let(:target) { '<div>&amp;content</div>' }

      it { is_expected.to eq target }
    end
  end
end
