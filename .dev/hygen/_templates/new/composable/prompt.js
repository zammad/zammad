// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module.exports = [
  {
    type: 'select',
    name: 'directoryScope',
    // eslint-disable-next-line zammad/zammad-detect-translatable-string
    message: 'Where should the component be created?',
    choices: [
      { directoryScope: 'desktop', message: 'Desktop' },
      { directoryScope: 'mobile', message: 'Mobile' },
      { directoryScope: 'shared', message: 'Shared' },
    ],
  },
  {
    type: 'input',
    name: 'composableName',
    // eslint-disable-next-line zammad/zammad-detect-translatable-string
    message: 'Composable name?',
  },
]
