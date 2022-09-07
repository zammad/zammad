class ProfileAppearance extends App.ControllerSubContent
  requiredPermission: 'user_preferences.apperance'
  header: __('Appearance')
  events:
    'change input[name="theme"]': 'updateTheme'

  constructor: ->
    super
    @render()
    @controllerBind('ui:theme:changed', @onUpdate)

  render: (theme) ->
    @html App.view('profile/appearance')(
      theme: theme || App.Session.get('preferences').theme || 'auto'
    )

  onUpdate: (event) =>
    if event.source != 'profile_appearance'
      @render event.detectedTheme

  updateTheme: (event) ->
    App.Event.trigger('ui:theme:set', { theme: event.target.value, source: 'profile_appearance' })

App.Config.set('Appearance', { prio: 900, name: __('Appearance'), parent: '#profile', target: '#profile/appearance', controller: ProfileAppearance, permission: ['user_preferences.appearance'] }, 'NavBarProfile')
