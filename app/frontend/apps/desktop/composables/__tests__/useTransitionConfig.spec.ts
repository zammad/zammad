// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { camelCase } from 'lodash-es'
import { ref } from 'vue'

import { useTransitionConfig, TransitionName } from '../useTransitionConfig.ts'

const hasReducedMotion = ref(false)

vi.mock('#shared/composables/useReducedMotion.ts', () => ({
  useReducedMotion: () => ({ hasReducedMotion }),
}))

describe('useTransitionConfig', () => {
  afterEach(() => {
    hasReducedMotion.value = false
  })

  it('returns actual transition names without reduced motion', () => {
    const { transitions } = useTransitionConfig()

    Object.entries(TransitionName).forEach(([key, name]) => {
      expect(transitions.value[camelCase(key)]).toBe(name)
    })
  })

  it('returns undefined for transition names with reduced motion', () => {
    hasReducedMotion.value = true

    const { transitions } = useTransitionConfig()

    Object.keys(TransitionName).forEach((key) => {
      if (key === 'Collapse') expect(transitions.value[camelCase(key)]).toBe('fade-quick')
      else expect(transitions.value[camelCase(key)]).toBeUndefined()
    })
  })
})
