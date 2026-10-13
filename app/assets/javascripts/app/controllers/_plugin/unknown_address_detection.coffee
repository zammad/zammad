# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class App.UnknownAddressDetection
  @notified: false

  # The same page on the configured address, or undefined when the current address is a configured one.
  @redirectUrl: (location = window.location) ->
    fqdn            = App.Config.get('fqdn')
    alternativeFqdn = App.Config.get('alternative_fqdn')
    httpType        = App.Config.get('http_type')

    # The placeholder FQDN of a fresh installation is not a real address, so there is nothing to redirect to.
    return if !fqdn || fqdn is 'zammad.example.com'

    configuredHosts = _.compact([fqdn, alternativeFqdn]).map((host) -> host.toLowerCase())

    hostMatches     = _.contains(configuredHosts, location.host.toLowerCase())
    protocolMatches = !httpType || location.protocol is "#{httpType}:"

    return if hostMatches && protocolMatches

    targetProtocol = httpType || location.protocol.slice(0, -1)

    "#{targetProtocol}://#{fqdn}#{location.pathname}#{location.search}#{location.hash}"

  @notify: (location = window.location) ->
    # Plugins are set up again on every login and logout, but the toast stays until it is clicked.
    return if @notified

    url = @redirectUrl(location)
    return if !url

    @notified = true

    App.Event.trigger('notify',
      type:    'warning'
      msg:     __("This isn't the address Zammad is set up for. Switch here.")
      link:    => @redirectUrl(location)
      timeout: false
    )

class App.UnknownAddressDetectionPlugin extends App.Controller
  constructor: ->
    super

    @controllerBind('notify:removeall', ->
      App.UnknownAddressDetection.notified = false
    )

    App.UnknownAddressDetection.notify()

App.Config.set('unknown_address_detection', App.UnknownAddressDetectionPlugin, 'Plugins')
