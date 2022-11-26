class ProfileAppearance extends App.ControllerSubContent
  requiredPermission: 'user_preferences.appearance'
  header: __('Appearance')
  events:
    'change input[name="theme"]': 'updateTheme'

  constructor: ->
    super
    @render()
    @controllerBind('ui:theme:changed', @render)

  render: (theme) ->
    @html App.view('profile/appearance')(
      theme: theme || App.Session.get('preferences').theme || 'auto'
    )

  updateTheme: (event) ->
    App.Event.trigger('ui:theme:set', { theme: event.target.value, save: true })

App.Config.set('Appearance', { prio: 900, name: __('Appearance'), parent: '#profile', target: '#profile/appearance', controller: ProfileAppearance, permission: ['user_preferences.appearance'] }, 'NavBarProfile')
