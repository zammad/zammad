class App.TwoFactorMethods
  @sortedMethods: ->
    all_methods = App.Config.get('TwoFactorMethods')

    _.sortBy all_methods, (elem) -> elem.order

  @methodByKey: (key) ->
    _.findWhere App.Config.get('TwoFactorMethods'), { key: key }


