// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { InMemoryCache } from '@apollo/client/core'
import type { InMemoryCacheConfig } from '@apollo/client/cache/inmemory/types'
import type { ImportGlobEagerDefault } from '@shared/types/utils'
import type {
  CacheInitializerModules,
  RegisterInMemoryCacheConfig,
} from '@shared/types/server/apollo/client'

let cacheConfig: InMemoryCacheConfig = {}

const cacheInitializerModules: CacheInitializerModules = import.meta.glob(
  './cache/initializer/*.ts',
  { eager: true },
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
