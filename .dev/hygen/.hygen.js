// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

const config = require('./lib.config.js')

module.exports = {
  helpers: {
    componentLibrary: (libraryName, path = true) => {
      if (libraryName === 'Desktop') return path ? 'apps/desktop' : 'desktop'
      if (libraryName === 'Mobile') return path ? 'apps/mobile' : 'mobile'
      if (libraryName === 'Shared') return 'shared'
    },
    composableName: (name, h) => {
      return h.changeCase.camel(`use${name}`)
    },
    componentGenericWitPrefix: (name, h) => {
      const nameWithGenericPrefix = name.replace(
        new RegExp(`${config.generic.prefix}`, 'i'),
        '',
      )
      return h.changeCase.pascal(
        `${config.generic.prefix}${h.changeCase.pascal(nameWithGenericPrefix)}`,
      )
    },
    zammadCopyright: () => {
      return `Copyright (C) 2012-${new Date().getFullYear()} Zammad Foundation, https://zammad-foundation.org/`
    },
  },
}
