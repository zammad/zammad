# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe HtmlSanitizer::Scrubber::TagRemove do
  subject(:actual) { fragment.scrub!(scrubber).to_html }

  let(:fragment)   { Loofah.fragment(input) }
  let(:scrubber)   { described_class.new }

  before do
    allow(Rails.application.config)
      .to receive(:html_sanitizer_tags_remove_content)
      .and_return(%w[tag-to-remove])
  end

  context 'when tags to be removed present' do
    let(:input)  { '<test></test><tag-to-remove></tag-to-remove>' }
    let(:target) { '<test></test>' }

    it { is_expected.to eq target }
  end

  context 'when tag to be removed is nested deep in tree' do
    let(:input)  { '<div><h1>Header<tag-to-remove></tag-to-remove></h1></div>' }
    let(:target) { '<div><h1>Header</h1></div>' }

    it { is_expected.to eq target }
  end

  context 'when tag to be removed has content inside' do
    let(:input)  { '<test></test><tag-to-remove><div>text</div></tag-to-remove>' }
    let(:target) { '<test></test>' }

    it { is_expected.to eq target }
  end

  context 'when custom tags list is given' do
    let(:scrubber) { described_class.new tags: %w[test] }
    let(:input)    { '<test></test><tag-to-remove><div>text</div></tag-to-remove>' }
    let(:target)   { '<tag-to-remove><div>text</div></tag-to-remove>' }

    it { is_expected.to eq target }
  end
end
