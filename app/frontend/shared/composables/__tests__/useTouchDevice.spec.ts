// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useTouchDevice } from '../useTouchDevice.ts'

const mockPointerCoarseMediaQuery = (initialMatchesQuery = false) => {
  let matchesQuery = initialMatchesQuery
  let observeCallback = vi.fn()

  // Impersonate a touch device state by mocking the corresponding media query in a dynamic manner.
  Object.defineProperty(window, 'matchMedia', {
    value: vi.fn().mockImplementation((query: string) => {
      if (query !== '(pointer: coarse)') return

      return {
        matches: matchesQuery,
        addEventListener: vi.fn().mockImplementation((type, listener) => {
          if (type !== 'change') return

          observeCallback = listener
        }),
        removeEventListener: vi.fn(),
      }
    }),
  })

  return (newMatchesQuery: boolean) => {
    matchesQuery = newMatchesQuery
    observeCallback()
  }
}

describe('isTouchDevice', () => {
  it('returns false for non-touch devices', () => {
    mockPointerCoarseMediaQuery(false)

    const { isTouchDevice } = useTouchDevice()

    expect(isTouchDevice.value).toBe(false)
  })

  it('returns true for non-touch devices', () => {
    mockPointerCoarseMediaQuery(true)

    const { isTouchDevice } = useTouchDevice()

    expect(isTouchDevice.value).toBe(true)
  })

  it('reacts to touch media query changes', () => {
    const changePointerCoarseMediaQuery = mockPointerCoarseMediaQuery()

    const { isTouchDevice } = useTouchDevice()

    expect(isTouchDevice.value).toBe(false)

    changePointerCoarseMediaQuery(true)

    expect(isTouchDevice.value).toBe(true)
  })
})
