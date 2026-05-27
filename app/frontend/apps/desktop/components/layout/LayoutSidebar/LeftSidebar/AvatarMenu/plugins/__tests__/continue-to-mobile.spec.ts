// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'

import continueToMobileItem from '../continue-to-mobile.ts'

const { getIsMobile, setIsMobile } = vi.hoisted(() => {
  let isMobile = false

  return {
    getIsMobile: () => isMobile,
    setIsMobile: (value: boolean) => {
      isMobile = value
    },
  }
})

vi.mock('#shared/utils/browser.ts', () => ({
  get isMobile() {
    return getIsMobile()
  },
}))

describe('avatar menu continue-to-mobile plugin', () => {
  beforeEach(() => {
    setIsMobile(false)
    localStorage.removeItem('forceDesktopApp')
  })

  it('is hidden by default on non-mobile devices', () => {
    setIsMobile(false)

    expect(continueToMobileItem.show?.()).toBe(false)
  })

  it('is shown on mobile devices', () => {
    setIsMobile(true)

    expect(continueToMobileItem.show?.()).toBe(true)
  })

  it('is shown when desktop mode was forced before', () => {
    setIsMobile(false)
    localStorage.setItem('forceDesktopApp', 'true')

    expect(continueToMobileItem.show?.()).toBeTruthy()
  })

  it('clears forced desktop mode when clicked', async () => {
    setIsMobile(false)
    localStorage.setItem('forceDesktopApp', 'true')

    continueToMobileItem.onClick?.()

    await waitFor(() => {
      expect(localStorage.getItem('forceDesktopApp')).toBeNull()
    })
  })
})
