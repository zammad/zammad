class ProfileNewBetaUI extends App.ControllerSubContent
  @requiredPermission: 'user_preferences'
  header: __('New BETA UI')

  constructor: ->
    super

    @render()

  render: (params) =>
    content = $(App.view('profile/newbetaui')())

    content.find('.js-switchControl').replaceWith App.UiElement.switch.render(
      name: 'desktop_beta_switch_profile'
      display: __('Display Zammad in the New BETA User Interface')
    )

    content.find('.js-checkboxControl').replaceWith App.UiElement.checkbox.render(
      name: 'desktop_beta_switch_dismiss'
      options:
        true: __('Have the BETA switch between the old and the new UI always available in the primary navigation')
      value: if App.DesktopBetaSwitch.isSwitchDismissed() then false else true
    )

    content.find('input[name="desktop_beta_switch_profile"]')
      .off('change.desktop_beta_switch_profile')
      .on('change.desktop_beta_switch_profile', (event) =>
        @delay(=>
          @updateNewBetaUI(event)
        , 250)
      )

    content.find('input[name="desktop_beta_switch_dismiss"]')
      .off('change.desktop_beta_switch_dismiss')
      .on('change.desktop_beta_switch_dismiss', (event) =>
        @preventDefaultAndStopPropagation()

        value = $(event.target).is(':checked')

        if value
          App.DesktopBetaSwitch.showSwitch()
          return

        App.DesktopBetaSwitch.dismissSwitch()
      )

    @html content

  updateNewBetaUI: (event) =>
    @preventDefaultAndStopPropagation()
    value = $(event.target).is(':checked')
    return if not value
    return if not App.DesktopBetaSwitch.activateSwitch()
    App.DesktopBetaSwitch.navigateToDesktop()

App.Config.set('NewBetaUI', {
  prio: 950,
  name: __('New BETA UI'),
  parent: '#profile',
  target: '#profile/newbetaui',
  controller: ProfileNewBetaUI,
  permission: (controller) ->
    return false if !App.Config.get('ui_desktop_beta_switch')

    role_ids = App.Config.get('ui_desktop_beta_switch_role_ids')

    return false if not _.isEmpty(role_ids) and not _.some(role_ids, (role_id) ->
      _.contains(App.User.current().role_ids, parseInt(role_id, 10))
    )

    controller.permissionCheck('user_preferences.beta_ui_switch')

}, 'NavBarProfile')
