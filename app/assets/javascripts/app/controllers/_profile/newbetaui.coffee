class ProfileNewBetaUI extends App.ControllerSubContent
  @requiredPermission: 'user_preferences'
  header: __('New Beta UI')

  constructor: ->
    super
    @render()
    @controllerBind('ui:beta:saved', @render)

  render: (params) =>
    content = $(App.view('profile/newbetaui')())

    content.find('.js-switchControl').replaceWith App.UiElement.switch.render(
      name: 'desktop_beta_switch_profile'
      display: __('Display Zammad in the New BETA User Interface')
    )

    content.find('.js-checkboxControl').replaceWith App.UiElement.checkbox.render(
      name: 'desktop_beta_switch_dismiss'
      options:
        true: __('Have the BETA switch between the old and the new UI always available in the Primary Navigation')
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

# TODO: Clarify permission!
App.Config.set('NewBetaUI', {
  prio: 950,
  name: __('New Beta UI'),
  parent: '#profile',
  target: '#profile/newbetaui',
  controller: ProfileNewBetaUI,
  permission: (controller) ->
    return false if !App.Config.get('ui_desktop_beta_switch')
    return controller.permissionCheck('user_preferences.beta_ui_switch')
}, 'NavBarProfile')
