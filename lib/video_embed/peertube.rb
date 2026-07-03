# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class VideoEmbed
  class Peertube < Backend
    def embed_url
      "https://#{host}/videos/embed/#{id}"
    end
  end
end
