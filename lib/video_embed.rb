# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class VideoEmbed
  include Mixin::HasBackends

  # Returns the embed URL for a stored video widget
  def self.embed_url(provider:, id:, host: nil)
    backend_class = lookup_provider(provider)
    return if !backend_class
    return if backend_class.self_hosted? && !self_hosted_host_allowed?(host)

    backend_class.new(id:, host:).embed_url
  end

  def self.lookup_provider(provider)
    backends.find { it.key == provider.to_s }
  end

  # Whether the given host is one of the self-hosted media servers an admin has approved.
  def self.self_hosted_host_allowed?(host)
    Setting.get('kb_self_hosted_video_servers').any? { it['host'] == host.to_s }
  end

  # Returns the list of allowed frame-src origins for the CSP.
  # This includes the built-in providers (YouTube, Vimeo)
  # and any self-hosted media servers the admin has listed.
  def self.frame_src
    (%w[www.youtube.com player.vimeo.com] + Setting.get('kb_self_hosted_video_servers').map { it['host'] })
      .map { "https://#{it}" }
  end
end
