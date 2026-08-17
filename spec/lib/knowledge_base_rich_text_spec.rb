# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe KnowledgeBaseRichText do
  describe '.resolve_answer_links' do
    let(:translation) { create(:knowledge_base_answer).translation_primary }

    def link(target_id)
      "<a href='#knowledge_base/1/locale/en-us/answer/9999' data-target-type='knowledge-base-answer' data-target-id='#{target_id}'>See also</a>"
    end

    it 'writes the href the block builds for the resolved translation' do
      result = described_class.resolve_answer_links(link(translation.id)) { |found| "/somewhere/#{found.answer_id}" }

      expect(result).to include(%(href="/somewhere/#{translation.answer_id}"))
    end

    it 'yields the target translation' do
      expect { |block| described_class.resolve_answer_links(link(translation.id), &block) }
        .to yield_with_args(translation)
    end

    it 'writes a placeholder href when the target translation is gone' do
      result = described_class.resolve_answer_links(link(9999)) { |found| "/somewhere/#{found.answer_id}" }

      expect(result).to include('href="#"')
    end

    it 'leaves links without a target marker alone' do
      result = described_class.resolve_answer_links('<a href="https://example.com">Example</a>') { '/somewhere' }

      expect(result).to include('href="https://example.com"')
    end
  end

  describe '.expand_video_widgets' do
    it 'renders a legacy (host-less) YouTube marker for backward compatibility' do
      result = described_class.expand_video_widgets('( widget: video, provider: youtube, id: vTTzwJsHpU8 )')
      expect(result).to include("src='https://www.youtube.com/embed/vTTzwJsHpU8'")
    end

    it 'renders a PeerTube marker' do
      allow(Setting).to receive(:get).with('kb_self_hosted_video_servers')
        .and_return([{ 'host' => 'video.example.com', 'name' => 'PT' }])

      marker = '( widget: video, provider: peertube, host: video.example.com, id: uuid-1 )'
      expect(described_class.expand_video_widgets(marker))
        .to include("src='https://video.example.com/videos/embed/uuid-1'")
    end

    it 'renders multiple markers in the same input' do
      input  = 'a ( widget: video, provider: youtube, id: aaa ) b ( widget: video, provider: vimeo, id: 111 ) c'
      result = described_class.expand_video_widgets(input)
      expect(result)
        .to include("src='https://www.youtube.com/embed/aaa'")
        .and include("src='https://player.vimeo.com/video/111'")
    end

    it 'escapes an id attribute breakout attempt (attribute injection)' do
      marker = "( widget: video, provider: youtube, id: a' srcdoc='&lt;img src=/api/v1/sessions/switch/1&gt;' b=' )"
      result = described_class.expand_video_widgets(marker)
      expect(result)
        .to include("src='https://www.youtube.com/embed/")
        .and satisfy { |r| r.exclude?("id='youtubea' srcdoc=") }
    end

    it 'renders nothing for an unrecognized provider' do
      marker = '( widget: video, provider: dailymotion, id: x )'
      expect(described_class.expand_video_widgets(marker)).to eq('')
    end
  end

  describe '.prepare' do
    it 'resolves links and expands video markers in one pass', :aggregate_failures do
      translation = create(:knowledge_base_answer).translation_primary
      input       = "<a data-target-type='knowledge-base-answer' data-target-id='#{translation.id}'>See also</a>" \
                    '<p>( widget: video, provider: youtube, id: aaa )</p>'

      result = described_class.prepare(input, &:desktop_url)

      expect(result).to include(%(href="#{translation.desktop_url}"))
      expect(result).to include("src='https://www.youtube.com/embed/aaa'")
    end
  end
end
