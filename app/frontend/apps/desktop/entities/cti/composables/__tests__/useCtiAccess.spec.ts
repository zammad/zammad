// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { useCtiAccess } from '../useCtiAccess.ts'

const allBackendsOff = {
  cti_integration: false,
  sipgate_integration: false,
  placetel_integration: false,
}

describe('useCtiAccess', () => {
  it.each(['cti_integration', 'sipgate_integration', 'placetel_integration'])(
    'is enabled with %s switched on',
    (setting) => {
      mockApplicationConfig({ ...allBackendsOff, [setting]: true })

      expect(useCtiAccess().isIntegrationEnabled.value).toBe(true)
    },
  )

  it('is disabled when no backend is switched on', () => {
    mockApplicationConfig(allBackendsOff)

    expect(useCtiAccess().isIntegrationEnabled.value).toBe(false)
  })
})
