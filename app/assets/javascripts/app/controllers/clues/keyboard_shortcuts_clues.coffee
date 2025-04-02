class App.KeyboardShortcutsClues extends App.CluesBase
  clues: [
    {
      container: '.user-menu .user .dropdown-menu a[href="#keyboard_shortcuts"]'
      headline: __('New Keyboard Shortcuts')
      text: __('You can open the Keyboard Shortcuts dialog here and view the new and improved layout, or revert to the old one if you prefer it.')
      actions: [
        'hover .navigation',
        'click .user-menu .user .js-action',
        'hover .user-menu .user a[href="#keyboard_shortcuts"]',
      ]
    }
  ]

App.Config.set('KeyboardShortcutsClues', { prio: 1000, controller: App.KeyboardShortcutsClues, preference_key: 'keyboard_shortcuts_clues' }, 'Clues')
