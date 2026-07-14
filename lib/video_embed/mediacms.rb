# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class VideoEmbed
  class Mediacms < Backend
    def self.self_hosted?
      true
    end

    def embed_url
      "https://#{host}/embed?m=#{id}"
    end
  end
end
