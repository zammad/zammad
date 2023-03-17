# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe HtmlSanitizer::Scrubber::Link do
  let(:scrubber) { described_class.new(web_app_url_prefix: 'http://example') }

  describe('#scrubber') do
    subject(:actual) { fragment.scrub!(scrubber).to_html }

    let(:fragment) { Loofah.fragment(input) }

    context 'when url as text' do
      let(:input)  { 'http://zammad.org' }
      let(:target) { '<a href="http://zammad.org" rel="nofollow noreferrer noopener" target="_blank">http://zammad.org</a>' }

      it { is_expected.to eq target }
    end

    context 'when a has no href' do
      let(:input)  { '<a>link</a>' }
      let(:target) { 'link' }

      it { is_expected.to eq target }
    end

    context 'when a has title' do
      let(:input)  { '<a title="test" href="http://example.org">link</a>' }
      let(:target) { '<a title="test" href="http://example.org" rel="nofollow noreferrer noopener">link</a>' }

      it { is_expected.to eq target }
    end

    context 'when a has no title' do
      let(:input)  { '<a href="http://example.org">link</a>' }
      let(:target) { '<a href="http://example.org" rel="nofollow noreferrer noopener" title="http://example.org">link</a>' }

      it { is_expected.to eq target }
    end

    context 'when external URL' do
      let(:input)  { '<a href="http://not.example.org">link</a>' }
      let(:target) { '<a href="http://not.example.org" rel="nofollow noreferrer noopener" target="_blank" title="http://not.example.org">link</a>' }

      it { is_expected.to eq target }
    end

    context 'when URL without protocol' do
      let(:input)  { '<a href="example.org">link</a>' }
      let(:target) { '<a href="example.org">link</a>' }

      it { is_expected.to eq target }
    end

    context 'when URL without protocol and external' do
      let(:scrubber) { described_class.new(web_app_url_prefix: 'http://example', external: true) }
      let(:input)  { '<a href="example.org">link</a>' }
      let(:target) { '<a href="http://example.org" rel="nofollow noreferrer noopener" title="http://example.org">link</a>' }

      it { is_expected.to eq target }
    end
  end
end
