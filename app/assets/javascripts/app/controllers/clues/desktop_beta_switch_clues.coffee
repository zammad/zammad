class App.DesktopBetaSwitchClues extends App.CluesBase
  clues: [
    {
      container: '.navbar-desktop-beta-switch'
      headline: __('New BETA UI')
      text: __('Hey! Zammad is getting a New Agent User Interface soon!¶Please try it out early and send your feedback on it.¶¶You can come back any time using the switch below.')
    }
  ]

App.Config.set('DesktopBetaSwitchClues', { prio: 2000, controller: App.DesktopBetaSwitchClues, preference_key: 'desktop_beta_switch_clues', config_key: 'ui_desktop_beta_switch', permission: ['user_preferences.beta_ui_switch'] }, 'Clues')
