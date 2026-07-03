# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe KnowledgeBaseRichTextHelper, type: :helper do
  describe '#prepare_rich_text_videos' do
    it 'renders a legacy (host-less) YouTube marker for backward compatibility' do
      result = helper.prepare_rich_text_videos('( widget: video, provider: youtube, id: vTTzwJsHpU8 )')
      expect(result).to include("src='https://www.youtube.com/embed/vTTzwJsHpU8'")
    end

    it 'renders a PeerTube marker' do
      marker = '( widget: video, provider: peertube, host: video.example.com, id: uuid-1 )'
      expect(helper.prepare_rich_text_videos(marker))
        .to include("src='https://video.example.com/videos/embed/uuid-1'")
    end

    it 'renders multiple markers in the same input' do
      input  = 'a ( widget: video, provider: youtube, id: aaa ) b ( widget: video, provider: vimeo, id: 111 ) c'
      result = helper.prepare_rich_text_videos(input)
      expect(result)
        .to include("src='https://www.youtube.com/embed/aaa'")
        .and include("src='https://player.vimeo.com/video/111'")
    end
  end
end
