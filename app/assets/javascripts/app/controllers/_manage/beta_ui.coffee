class App.BetaUI extends App.ControllerSubContent
  header: __('BETA UI Availability')
  description: __('''
This service configures the usage and consent to participate in the BETA research of the new UI.

As an administrator, you can configure which roles in your Zammad instance can get an easy access to the new UI.

Each of the users can then provide consent or not for the participation in the BETA program.

Answers will be anonymized and the data collected consists of:
- Zammad instance name
- star rating of the new UI
- text comments on the new UI
- amount of tracked hours in the new UI
''')
  requiredPermission: 'admin.beta_ui'
  events:
    'change .js-betaUIToggle input': 'toggleBetaUISetting'
    'click .js-submit': 'saveBetaUIRolesSetting'

  elements:
    '.js-betaUIToggle input': 'betaUIToggle'

  constructor: ->
    super

    @controllerBind('config_update', (data) =>
      if data.name is 'ui_desktop_beta_switch' and not @betaUISettingUpdated
        @betaUIToggle.prop('checked', App.Config.get('ui_desktop_beta_switch'))
      else if data.name is 'ui_desktop_beta_switch_role_ids' and not @betaUIRolesSettingUpdated
        @render()

      @betaUISettingUpdated = false if @betaUISettingUpdated
      @betaUIRolesSettingUpdated = false if @betaUIRolesSettingUpdated
    )

    App.Setting.fetchFull(
      @render
      force: false
    )

  render: =>
    content = $(App.view('beta_ui')(
      header: @header
      description: marked(App.i18n.translateContent(@description))
    ))

    new App.ControllerForm(
      el: content.find('.form-item')
      model:
        configure_attributes: [
          display:   __('Limit availability of the BETA UI to roles')
          null:      true
          name:      'ui_desktop_beta_switch_role_ids'
          tag:       'column_select'
          relation:  'Role'
          translate: true
        ]
      autofocus: false
      params:
        ui_desktop_beta_switch_role_ids: App.Config.get('ui_desktop_beta_switch_role_ids')
    )

    @html content

  toggleBetaUISetting: =>
    value = @betaUIToggle.prop('checked')
    App.Setting.set('ui_desktop_beta_switch', value, failLocal: @render, doneLocal: =>
      @betaUISettingUpdated = true
      App.Event.trigger('ui:rerender')
    , notify: true)

  saveBetaUIRolesSetting: (e) =>
    e.preventDefault()
    params = @formParam(e.target)
    App.Setting.set('ui_desktop_beta_switch_role_ids', params['ui_desktop_beta_switch_role_ids'], notify: true, failLocal: @render, doneLocal: =>
      @betaUIRolesSettingUpdated = true
      App.Event.trigger('ui:rerender')
    )

App.Config.set('BetaUI', { prio: 1100, name: __('BETA UI'), parent: '#settings', target: '#settings/beta_ui', controller: App.BetaUI, permission: ['admin.beta_ui'], setting: ['ui_desktop_beta_switch_admin_menu'] }, 'NavBarAdmin')
