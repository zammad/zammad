// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { Initializer, InitializerModule } from '@common/types/initializer'
import { ImportGlobEagerResult } from '@common/types/utils'
import { App } from 'vue'

export default class InitializeHandler implements Initializer {
  app: App

  modules: Array<InitializerModule>

  constructor(app: App, specificAppModules?: ImportGlobEagerResult) {
    this.app = app

    const commonInitializerModules = import.meta.globEager('./initializer/*.ts')

    this.modules = Object.values(commonInitializerModules).map(
      (module) => module.default,
    )

    if (specificAppModules) {
      const loadedSpecificAppModules: Array<InitializerModule> = Object.values(
        specificAppModules,
      ).map((module) => module.default as InitializerModule)

      this.modules.push(...loadedSpecificAppModules)
    }
  }

  initialize() {
    this.modules.forEach((module: InitializerModule) => {
      module(this.app)
    })
  }
}
