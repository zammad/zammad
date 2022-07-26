// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { merge } from 'lodash-es'
import { plugin as formPlugin } from '@formkit/vue'

import { buildFormKitPluginConfig } from '@shared/form'
import initializeGlobalComponents from '@shared/initializer/globalComponents'

// imported only for types
// for some reason adding it to tsconfig doesn't work
import '@testing-library/cypress'
import 'cypress-real-events'
import '../types/commands'

// TODO
// @ts-expect-error untyped arguments
export const mountComponent: typeof mount = (component, options) => {
  const plugins = []
  plugins.push(initializeGlobalComponents)
  plugins.push([formPlugin, buildFormKitPluginConfig()])
  return cy.mount(component, merge({ global: { plugins } }, options))
}

export default {}
