# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class App.KnowledgeBaseVideo
  @MARKER: /\(([\s]*)widget:([\s]*)video[\W]([\s\S])+?\)/g

  # Mirrors the VideoEmbed backends.
  @PROVIDERS:
    youtube:
      embedUrl: (id) -> "https://www.youtube.com/embed/#{id}"
      watchUrl: (id) -> "https://www.youtube.com/watch?v=#{id}"
    vimeo:
      embedUrl: (id) -> "https://player.vimeo.com/video/#{id}"
      watchUrl: (id) -> "https://vimeo.com/#{id}"
    peertube:
      selfHosted: true
      embedUrl: (id, host) -> "https://#{host}/videos/embed/#{id}"
      watchUrl: (id, host) -> "https://#{host}/videos/watch/#{id}"
    mediacms:
      selfHosted: true
      embedUrl: (id, host) -> "https://#{host}/embed?m=#{id}"
      watchUrl: (id, host) -> "https://#{host}/view?m=#{id}"

  # Replaces each video widget marker in the input with what the callback returns for its settings.
  @replaceMarkers: (input, callback) ->
    input.replace @MARKER, (marker) => callback(@widgetSettings(marker))

  # Replaces each video widget marker in the text of the element with the node the callback returns
  #   for its settings, or removes it. A marker in an attribute value is no widget and stays as is.
  @replaceMarkersInText: (element, callback) ->
    textNodes = $(element).find('*').addBack().contents().filter(-> @nodeType is Node.TEXT_NODE)

    for textNode in textNodes.toArray()
      text  = textNode.nodeValue
      nodes = []
      start = 0

      for match in Array.from(text.matchAll(@MARKER))
        nodes.push document.createTextNode(text.slice(start, match.index))
        replacement = callback(@widgetSettings(match[0]))
        nodes.push replacement if replacement
        start = match.index + match[0].length

      continue if !nodes.length

      nodes.push document.createTextNode(text.slice(start))
      $(textNode).replaceWith(nodes)

  @widgetSettings: (marker) ->
    settings = {}

    for pair in marker.slice(1, -1).split(',')
      index = pair.indexOf(':')
      continue if index < 0

      settings[pair.slice(0, index).trim()] = pair.slice(index + 1).trim()

    settings

  @embedUrl: (settings) ->
    @url(settings, 'embedUrl')

  @watchUrl: (settings) ->
    # Without an ID the link would point to the provider's front page.
    return if !settings.id

    @url(settings, 'watchUrl')

  @url: (settings, type) ->
    return if !_.has(@PROVIDERS, settings.provider)

    provider = @PROVIDERS[settings.provider]
    return if provider.selfHosted && !@hostAllowed(settings.host)

    provider[type](encodeURIComponent(settings.id ? ''), @escapeHost(settings.host ? ''))

  # Whether the given host is one of the self-hosted media servers an admin has
  # approved (see Setting 'kb_self_hosted_video_servers').
  @hostAllowed: (host) ->
    return false if !host

    _.some App.Config.get('kb_self_hosted_video_servers'), (server) -> server.host == host

  # An admin-approved server may carry an explicit port (see
  # Setting::Validation::KbSelfHostedVideoServers), which must stay a literal ':'
  # delimiter - escaping it would point the iframe at a host that does not exist, and
  # no longer match the origin allowed via the CSP frame-src. The host name itself is
  # still escaped, so a value that somehow entered the setting without passing its
  # validation cannot break out of the surrounding attribute.
  @escapeHost: (host) ->
    index = host.lastIndexOf(':')
    name  = host.slice(0, index)
    port  = host.slice(index + 1)

    return encodeURIComponent(host) if index < 1 || !/^\d+$/.test(port)

    "#{encodeURIComponent(name)}:#{port}"
