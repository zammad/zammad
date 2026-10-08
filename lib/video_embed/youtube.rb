# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class VideoEmbed
  class Youtube < Backend
    def embed_url
      "https://www.youtube.com/embed/#{id}"
    end

    def watch_url
      "https://www.youtube.com/watch?v=#{id}"
    end
  end
end
