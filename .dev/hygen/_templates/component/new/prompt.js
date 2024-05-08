// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module.exports = [
  {
    type: 'select',
    name: 'libraryName',
    // eslint-disable-next-line zammad/zammad-detect-translatable-string
    message: 'Where should the component be created?',
    choices: [
      { libraryName: 'desktop', message: 'Desktop' },
      { libraryName: 'mobile', message: 'Mobile' },
      { libraryName: 'shared', message: 'Shared' },
    ],
  },
  {
    type: 'input',
    name: 'name',
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
