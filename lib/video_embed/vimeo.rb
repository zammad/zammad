# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class VideoEmbed
  class Vimeo < Backend
    def embed_url
      "https://player.vimeo.com/video/#{id}"
    end

    def watch_url
      "https://vimeo.com/#{id}"
    end
  end
end
