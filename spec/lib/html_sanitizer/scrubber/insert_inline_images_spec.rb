# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe HtmlSanitizer::Scrubber::InsertInlineImages, current_user_id: 1 do
  let(:scrubber) { described_class.new(sample.attachments) }
  let(:sample)   { create(:ticket_shared_draft_start, :with_inline_image) }

  describe '#scrub' do
    subject(:actual) { fragment.scrub!(scrubber).to_html }

    let(:fragment) { Loofah.fragment(sample.body) }

    it 'converts images from cid to base64 sources' do
      original = attributes_for(:ticket_shared_draft_start, :with_inline_image)
      expect(actual).to eq original.dig(:content, :body)
    end
  end
end
