// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { InMemoryCache } from '@apollo/client/core'
import type { InMemoryCacheConfig } from '@apollo/client/cache/inmemory/types'
import type { ImportGlobEagerDefault } from '@common/types/utils'
import type {
  CacheInitializerModules,
  RegisterInMemoryCacheConfig,
} from '@common/types/server/apollo/client'

let cacheConfig: InMemoryCacheConfig = {}

const cacheInitializerModules: CacheInitializerModules = import.meta.globEager(
  './cache/initializer/*.ts',
)

const registerInitializeModules = (
  additionalCacheInitializerModules: CacheInitializerModules = {},
) => {
  const allCacheInitializerModules = Object.assign(
    cacheInitializerModules,
    additionalCacheInitializerModules,
  )

  Object.values(allCacheInitializerModules).forEach(
    (module: ImportGlobEagerDefault<RegisterInMemoryCacheConfig>) => {
      const register = module.default

      cacheConfig = register(cacheConfig)
    },
  )
}

const createCache = (
  additionalCacheInitializerModules: CacheInitializerModules = {},
): InMemoryCache => {
  registerInitializeModules(additionalCacheInitializerModules)

  return new InMemoryCache(cacheConfig)
}

export default createCache
