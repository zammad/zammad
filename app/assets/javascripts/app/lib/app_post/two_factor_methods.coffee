class App.TwoFactorMethods
  @sortedMethods: ->
    _.sortBy App.Config.get('TwoFactorMethods'), (elem) -> elem.order

  @methodByKey: (key) ->
    _.findWhere App.Config.get('TwoFactorMethods'), { key: key }

  @authenticationMethods: ->
    _.where @sortedMethods(), { authenticationMethod: true }

  @isAnyAuthenticationMethodEnabled: ->
    _.some @authenticationMethods(), (elem) -> App.Config.get(elem.settingKey)
