// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { InMemoryCache } from '@apollo/client/core'
import type { InMemoryCacheConfig } from '@apollo/client/cache/inmemory/types'
import { ImportGlobEagerDefault } from '@common/types/utils'

let cacheConfig = {}

const cacheInitializerModules = import.meta.globEager(
  './cache/initializer/*.ts',
)

type RegisterInMemoryCacheConfig = (
  config: InMemoryCacheConfig,
) => InMemoryCacheConfig

Object.values(cacheInitializerModules).forEach(
  (module: ImportGlobEagerDefault<RegisterInMemoryCacheConfig>) => {
    const register = module.default

    cacheConfig = register(cacheConfig)
  },
)

export default new InMemoryCache(cacheConfig)
