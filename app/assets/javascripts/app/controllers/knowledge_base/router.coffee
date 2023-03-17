class Router extends App.ControllerPermanent
  requiredPermission: 'knowledge_base.*'

  constructor: (params) ->
    super

    if params['locale']
      params.selectedSystemLocale = App.Locale.findByAttribute('locale', params['locale'])
      params.selectedSystemLocalePresent = true

    # check authentication
    @authenticateCheckRedirect()

    App.TaskManager.execute(
      key:        'KnowledgeBase'
      controller: 'KnowledgeBaseAgentController'
      params:     params
      show:       true
      persistent: true
    )

[
  '/category/:category_id'
  '/answer/:answer_id'
  ''
]
  .reduce((memo, elem) ->
    memo.concat [elem, elem + '/:action', elem + '/:action/:arguments']
  , [])
  .forEach (elem) ->
    url = "knowledge_base/:knowledge_base_id/locale/:locale#{elem}" # App.Utils not yet available, thus not using App.Utils.joinUrlComponents
    App.Config.set(url, Router, 'Routes')

App.Config.set('knowledge_base', Router, 'Routes')

