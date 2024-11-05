// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

const config = require('./lib.config.js')

module.exports = {
  helpers: {
    componentLibrary: (directoryScope, path = true) => {
      if (directoryScope === 'Desktop') return path ? 'apps/desktop' : 'desktop'
      if (directoryScope === 'Mobile') return path ? 'apps/mobile' : 'mobile'
      if (directoryScope === 'Shared') return 'shared'

      throw new Error('Directory scope not found')
    },
    getPath(type, options) {
      switch (type) {
        case 'genericComponent':
          return `../../app/frontend/${this.componentLibrary(options.directoryScope)}/components/${options.suffix}`
        case 'composable':
          return `../../app/frontend/${this.componentLibrary(options.directoryScope)}/composables/${options.suffix}`
        case 'store':
          return `../../app/frontend/${this.componentLibrary(options.directoryScope)}/stores/${options.suffix}`
        default:
          return type
      }
    },
    zammadCopyright: () => {
      return `Copyright (C) 2012-${new Date().getFullYear()} Zammad Foundation, https://zammad-foundation.org/`
    },
    usePrefix(name, type = 'use') {
      if (type === 'use') {
        const nameWithGenericPrefix = name.replace(
          new RegExp(`${config.convention.vue.use}`, 'i'),
          '',
        )
        return this.changeCase.camel(
          `${config.convention.vue.use}${this.changeCase.pascal(nameWithGenericPrefix)}`,
        )
      }

      if (type === 'generic') {
        const nameWithGenericPrefix = name.replace(
          new RegExp(`${config.generic.prefix}`, 'i'),
          '',
        )
        return this.changeCase.pascal(
          `${config.generic.prefix}${this.changeCase.pascal(nameWithGenericPrefix)}`,
        )
      }
    },
  },
}
