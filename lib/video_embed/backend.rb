# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class VideoEmbed
  # Base class for all video embed providers. A provider knows how to turn a
  # stored video widget (provider + host + id) into an embeddable iframe URL
  class Backend
    attr_reader :id, :host, :servers

    def initialize(id:, host: nil)
      @id      = CGI.escape(id.to_s)
      @host    = host
    end

    # Provider key as stored in the widget marker, e.g. "youtube".
    def self.key
      name.demodulize.underscore
    end

    # The full embed URL for this provider. Must be implemented by subclasses.
    def embed_url
      raise NotImplementedError
    end
  end
end
