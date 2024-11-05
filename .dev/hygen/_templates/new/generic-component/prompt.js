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
    name: 'componentName',
    // eslint-disable-next-line zammad/zammad-detect-translatable-string
    message: 'Component name?',
  },
  {
    type: 'confirm',
    name: 'withComposable',
    // eslint-disable-next-line zammad/zammad-detect-translatable-string
    message: 'Should generate a composable?',
    initial: true,
  },
  {
    type: 'confirm',
    name: 'withTypeFile',
    // eslint-disable-next-line zammad/zammad-detect-translatable-string
    message: 'Should generate a type file?',
    initial: true,
  },
]
