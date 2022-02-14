// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import initializeForm, { getFormPlugins } from '@common/form'
import type { ImportGlobEagerOutput } from '@common/types/utils'
import type { FormKitPlugin } from '@formkit/core'
import { createApp } from 'vue'

describe('getFormPlugins', () => {
  // eslint-disable-next-line @typescript-eslint/no-empty-function
  const examplePlugin = (): void => {}
  const pluginModules: ImportGlobEagerOutput<FormKitPlugin> = {
    'common/test/plugins/test.ts': {
      default: examplePlugin,
    },
    'common/test/plugins/example.ts': {
      default: examplePlugin,
    },
  }

  it('should return the plugin list', () => {
    expect(getFormPlugins(pluginModules)).toEqual([
      examplePlugin,
      examplePlugin,
    ])
  })
})

describe('initializeForm', () => {
  const app = createApp({})

  jest.spyOn(app, 'use')

  it('check use form plugin without an error', () => {
    initializeForm(app)

    expect(app.use).toHaveBeenCalled()
  })
})
