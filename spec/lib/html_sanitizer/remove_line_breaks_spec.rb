# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe HtmlSanitizer::RemoveLineBreaks do
  let(:scrubber) { described_class.new }

  describe('#scrubber') do
    subject(:actual) { fragment.scrub!(scrubber).to_html }

    let(:fragment) { Loofah.fragment(input) }

    describe 'removes newline-only spans' do
      let(:input)  { "<div>test<span>a\n</span><span>\r\n</span></div>" }
      let(:target) { "<div>testa\n</div>" }

      it { is_expected.to match target }
    end

    describe 'removes newline-only in divs' do
      let(:input)  { "<div>test<div>a\n</div><div>\r\n\n\n</div></div>" }
      let(:target) { "<div>test<div>a\n</div>\n</div>" }

      it { is_expected.to match target }
    end

    describe 'does not remove newlines in other elements' do
      let(:input)  { "<div>test<output>a\n</output></div>" }
      let(:target) { "<div>test<output>a\n</output>\n</div>" }

      it { is_expected.to match target }
    end
  end
end
