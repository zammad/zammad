# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe VideoEmbed do
  describe '.embed_url' do
    context 'with a built-in provider (fixed origin)' do
      it 'builds the YouTube embed URL from the fixed origin' do
        expect(described_class.embed_url(provider: 'youtube', id: 'abc-123'))
          .to eq('https://www.youtube.com/embed/abc-123')
      end

      it 'builds the Vimeo embed URL from the fixed origin' do
        expect(described_class.embed_url(provider: 'vimeo', id: '987654'))
          .to eq('https://player.vimeo.com/video/987654')
      end
    end

    context 'with a self-hosted provider' do
      it 'builds the PeerTube embed URL when the host is whitelisted' do
        expect(described_class.embed_url(provider: 'peertube', id: 'uuid-1', host: 'video.example.com'))
          .to eq('https://video.example.com/videos/embed/uuid-1')
      end

      it 'builds the MediaCMS embed URL when the host is whitelisted' do
        expect(described_class.embed_url(provider: 'mediacms', id: 'token1', host: 'cms.example.org'))
          .to eq('https://cms.example.org/embed?m=token1')
      end
    end

    context 'with unsafe or unknown input' do
      it 'returns nil for an unknown provider' do
        expect(described_class.embed_url(provider: 'dailymotion', id: 'x')).to be_nil
      end

      it 'returns escaped ID containing markup (XSS attempt)' do
        expect(described_class.embed_url(provider: 'youtube', id: %q{'"><script>alert(1)</script>}))
          .not_to include('<script>')
      end
    end
  end

  describe '.frame_src' do
    it 'always includes the built-in origins' do
      expect(described_class.frame_src)
        .to contain_exactly('https://www.youtube.com', 'https://player.vimeo.com')
    end

    context 'when self-hosted servers are configured' do
      let(:servers) do
        [
          { 'host' => 'video.example.com', 'name' => 'PT' },
          { 'host' => 'cms.example.org', 'name' => 'CMS' },
        ]
      end

      before do
        allow(Setting).to receive(:get).with('kb_self_hosted_video_servers').and_return(servers)
      end

      it 'includes whitelisted self-hosted hosts' do
        expect(described_class.frame_src)
          .to include('https://video.example.com', 'https://cms.example.org')
      end
    end
  end
end
