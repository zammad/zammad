// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { createPinia, setActivePinia } from 'pinia'

import {
  mockApplicationConfigQuery,
  mockApplicationConfigQueryError,
} from '#shared/graphql/queries/applicationConfig.mocks.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

import { useApplicationStore } from '../application.ts'

describe('application store', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('loads the config', async () => {
    mockApplicationConfigQuery({
      applicationConfig: [{ key: 'product_name', value: 'Zammad Test' }],
    })

    const application = useApplicationStore()

    await application.getConfig()

    expect(application.config.product_name).toBe('Zammad Test')
  })

  it('rejects when the config cannot be loaded', async () => {
    mockApplicationConfigQueryError('Config unavailable', {
      type: GraphQLErrorTypes.UnknownError,
    })

    await expect(useApplicationStore().getConfig()).rejects.toThrow('Config unavailable')
  })
})
