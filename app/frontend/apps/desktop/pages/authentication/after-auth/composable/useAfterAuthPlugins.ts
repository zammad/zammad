// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { keyBy } from 'lodash-es'
import { computed, ref } from 'vue'

import type {
  EnumAfterAuthType,
  SessionAfterAuth,
} from '#shared/graphql/types.ts'

import type { AfterAuthPlugin } from '../types.ts'
import type { Router } from 'vue-router'

const pluginsModules = import.meta.glob<AfterAuthPlugin>('../plugins/*.ts', {
  eager: true,
  import: 'default',
})

const pluginsFiles = Object.values(pluginsModules)

const plugins = keyBy(pluginsFiles, 'name')

const currentPlugin = ref<EnumAfterAuthType | null>(null)
const currentPluginData = ref<Record<string, unknown> | null>(null)

export const ensureAfterAuth = async (
  router: Router,
  afterAuth: SessionAfterAuth,
) => {
  currentPlugin.value = afterAuth.type
  currentPluginData.value = afterAuth.data || null

  await router.replace('/login/after-auth')
}

export const useAfterAuthPlugins = () => {
  const plugin = computed(() => {
    if (!currentPlugin.value) return null
    return plugins[currentPlugin.value] || null
  })
  return {
    currentPlugin: plugin,
    data: currentPluginData,
    plugins,
  }
}
