# coffeelint: disable=camel_case_classes
class App.UiElement.auth_provider
  @render: (attributeConfig) ->
    attribute = $.extend(true, {}, attributeConfig)

    for key, value of App.Config.get('auth_provider_all')
      continue if value.config isnt attribute.provider
      attribute.value = "#{App.Config.get('http_type')}://#{App.Config.get('fqdn')}#{value.url}/callback"
      break

    $( App.view('generic/auth_provider')( attribute: attribute ) )
