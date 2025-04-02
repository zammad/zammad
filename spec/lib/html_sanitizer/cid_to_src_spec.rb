# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe HtmlSanitizer::CidToSrc do
  let(:scrubber) { described_class.new }

  describe('#scrubber') do
    subject(:actual) { fragment.scrub!(scrubber).to_html }

    let(:fragment) { Loofah.fragment(input) }

    describe 'does not touch images without cid' do
      let(:input)  { '<img src="test.jpg">' }
      let(:target) { '<img src="test.jpg">' }

      it { is_expected.to match target }
    end

    describe 'replaces source to cid when present' do
      let(:input)  { '<img src="test.jpg" cid="img_cid">' }
      let(:target) { '<img src="cid:img_cid">' }

      it { is_expected.to match target }
    end

    describe 'does not touch non-images' do
      let(:input)  { '<div cid="test"></div>' }
      let(:target) { '<div cid="test"></div>' }

      it { is_expected.to match target }
    end
  end
end
