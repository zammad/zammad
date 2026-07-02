// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import { useReducedMotion } from '../useReducedMotion.ts'

const preferredMotion = ref('no-preference')

vi.mock('@vueuse/core', () => ({
  usePreferredReducedMotion: () => preferredMotion,
}))

describe('useReducedMotion', () => {
  afterEach(() => {
    vi.unstubAllGlobals()
    preferredMotion.value = 'no-preference'
  })

  describe('hasReducedMotion', () => {
    it('returns true in test environment', () => {
      const { hasReducedMotion } = useReducedMotion()

      expect(hasReducedMotion.value).toBe(true)
    })

    it('returns false when user has no motion preference', () => {
      vi.stubGlobal('VITE_TEST_MODE', false)

      const { hasReducedMotion } = useReducedMotion()

      expect(hasReducedMotion.value).toBe(false)
    })

    it('returns true when user prefers reduced motion', () => {
      vi.stubGlobal('VITE_TEST_MODE', false)

      preferredMotion.value = 'reduce'

      const { hasReducedMotion } = useReducedMotion()

      expect(hasReducedMotion.value).toBe(true)
    })

    describe('scrollBehavior', () => {
      it('returns "instant" in test environment', () => {
        const { scrollBehavior } = useReducedMotion()

        expect(scrollBehavior.value).toBe('instant')
      })

      it('returns "smooth" when user has no motion preference', () => {
        vi.stubGlobal('VITE_TEST_MODE', false)

        const { scrollBehavior } = useReducedMotion()

        expect(scrollBehavior.value).toBe('smooth')
      })

      it('returns "instant" when user prefers reduced motion', () => {
        vi.stubGlobal('VITE_TEST_MODE', false)

        preferredMotion.value = 'reduce'

        const { scrollBehavior } = useReducedMotion()

        expect(scrollBehavior.value).toBe('instant')
      })
    })
  })
})
