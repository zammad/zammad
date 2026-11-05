// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { FormKit } from '@formkit/vue'
import { provideApolloClient } from '@vue/apollo-composable'
import { createMockClient } from 'mock-apollo-client'
import { onTestFinished } from 'vitest'
import { commands } from 'vitest/browser'
import { render } from 'vitest-browser-vue'
import { createMemoryHistory, createRouter } from 'vue-router'

import type { FormSchemaField } from '#shared/components/Form/types.ts'
import { initializeAppName } from '#shared/composables/useAppName.ts'
import initializeGlobalComponents from '#shared/initializer/globalComponents.ts'
import initializeGlobalProperties from '#shared/initializer/globalProperties.ts'
import createCache from '#shared/server/apollo/cache.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import initializeStore from '#shared/stores/index.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import type { UserData } from '#shared/types/store.ts'

import { initializeForm, initializeFormFields } from '#mobile/form/index.ts'
import { initializeGlobalComponentStyles } from '#mobile/initializer/initializeGlobalComponentStyles.ts'
import initializeGlobalDirectives from '#mobile/initializer/initializeGlobalDirectives.ts'
import { initializeMobileIcons } from '#mobile/initializer/initializeMobileIcons.ts'
import { initializeMobileVisuals } from '#mobile/initializer/mobileVisuals.ts'
import { cacheInitializerModules } from '#mobile/server/apollo/index.ts'

import type { RouteResponse } from './commands.mts'
import type { MountOptions } from './types.ts'
import type { App, Component } from 'vue'

// The store outlives the test, so a mount without permissions must not see those of an earlier one.
const mockPermissions = (permissions?: string[]) => {
  const session = useSessionStore()

  session.user = permissions
    ? ({
        __typename: 'User',
        id: '123',
        internalId: 1,
        objectAttributeValues: [],
        permissions: { __typename: 'UserPermission', names: permissions },
      } as unknown as UserData)
    : null
}

export const mountComponent = (
  component: Component,
  props: Record<string, unknown> = {},
  { config, permissions }: MountOptions = {},
) => {
  const router = createRouter({
    history: createMemoryHistory('/'),
    routes: [{ path: '/', component: { template: '<div />' } }],
  })

  const plugins = [
    () => initializeAppName('mobile'),
    initializeStore,
    () => Object.assign(useApplicationStore().config, config),
    () => mockPermissions(permissions),
    initializeGlobalComponentStyles,
    initializeGlobalComponents,
    initializeGlobalDirectives,
    initializeGlobalProperties,
    initializeMobileIcons,
    initializeForm,
    initializeFormFields,
    initializeMobileVisuals,
    (app: App) => router.install(app),
  ]

  return render(component, { props, global: { plugins } })
}

export const mountFormField = (
  field: string,
  props?: Partial<FormSchemaField> & Record<string, unknown>,
) =>
  mountComponent(FormKit, {
    name: field,
    type: field,
    ...props,
  })

export const mockApolloClient = () => {
  const client = createMockClient({
    cache: createCache(cacheInitializerModules),
    queryDeduplication: true,
  })
  provideApolloClient(client)

  return client
}

// The page and its routes outlive the test, other test files run on it afterwards.
export const routeRequest = async (url: string, response: RouteResponse) => {
  await commands.routeRequest(url, response)

  onTestFinished(() => commands.unrouteRequest(url))
}
