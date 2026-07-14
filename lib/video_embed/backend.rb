# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class VideoEmbed
  # Base class for all video embed providers. A provider knows how to turn a
  # stored video widget (provider + host + id) into an embeddable iframe URL
  class Backend
    attr_reader :id, :host, :servers

    def initialize(id:, host: nil)
      @id      = CGI.escape(id.to_s)
      @host    = host.present? ? CGI.escape(host.to_s) : nil
    end

    # Provider key as stored in the widget marker, e.g. "youtube".
    def self.key
      name.demodulize.underscore
    end

    # Whether this provider's host must match an admin-approved
    # self-hosted media server (see Setting 'kb_self_hosted_video_servers').
    def self.self_hosted?
      false
    end

    # The full embed URL for this provider. Must be implemented by subclasses.
    def embed_url
      raise NotImplementedError
    end
  end
end
