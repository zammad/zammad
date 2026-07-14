# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe KnowledgeBaseRichTextHelper, type: :helper do
  describe '#prepare_rich_text_videos' do
    it 'renders a YouTube marker' do
      marker = '( widget: video, provider: youtube, id: aaa )'
      expect(helper.prepare_rich_text_videos(marker))
        .to include("src='https://www.youtube.com/embed/aaa'")
    end

    it 'renders a Vimeo marker' do
      marker = '( widget: video, provider: vimeo, id: 111 )'
      expect(helper.prepare_rich_text_videos(marker))
        .to include("src='https://player.vimeo.com/video/111'")
    end

    it 'renders multiple markers in the same input' do
      input = '( widget: video, provider: youtube, id: aaa ) and ( widget: video, provider: vimeo, id: 111 )'
      expect(helper.prepare_rich_text_videos(input))
        .to include("src='https://www.youtube.com/embed/aaa'")
        .and include("src='https://player.vimeo.com/video/111'")
    end

    it 'escapes an id attribute breakout attempt (attribute injection)' do
      marker = "( widget: video, provider: youtube, id: a' srcdoc='&lt;img src=/api/v1/sessions/switch/1&gt;' b=' )"
      result = helper.prepare_rich_text_videos(marker)
      expect(result)
        .to include("src='https://www.youtube.com/embed/")
        .and satisfy { |r| r.exclude?("id='youtubea' srcdoc=") }
    end

    it 'leaves the marker untouched for an unrecognized provider' do
      marker = '( widget: video, provider: dailymotion, id: x )'
      expect(helper.prepare_rich_text_videos(marker)).to eq(marker)
    end

    it 'does not raise when a value contains a colon' do
      marker = '( widget: video, provider: youtube, id: aa:bb )'
      expect { helper.prepare_rich_text_videos(marker) }.not_to raise_error
    end
  end
end
