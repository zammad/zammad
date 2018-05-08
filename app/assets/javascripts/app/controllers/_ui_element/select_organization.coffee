class App.UiElement.select_organization extends App.UiElement.select
  @render: (attribute, params) ->
    if attribute['name'] == 'organization_id' && attribute['default'] == 0
      attribute['default'] = attribute['filter'][0]
    super(attribute, params)