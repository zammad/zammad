# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class App.KnowledgeBaseVideo
  # Whether the given host is one of the self-hosted media servers an admin has
  # approved (see Setting 'kb_self_hosted_video_servers').
  @hostAllowed: (host) ->
    return false if !host

    _.some App.Config.get('kb_self_hosted_video_servers'), (server) -> server.host == host
