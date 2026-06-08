// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'

import { useMobileDetection } from '../useMobileDetection.ts'

const { notifyMock, removeNotificationMock } = vi.hoisted(() => ({
  notifyMock: vi.fn(),
  removeNotificationMock: vi.fn(),
}))

vi.mock('#shared/components/CommonNotifications/useNotifications.ts', () => ({
  useNotifications: () => ({
    notify: notifyMock,
    removeNotification: removeNotificationMock,
  }),
}))

type MatchMediaListener = (event: MediaQueryListEvent) => void

let matchesState = false
const listeners = new Set<MatchMediaListener>()

const triggerMatchMediaChange = (matches: boolean) => {
  matchesState = matches

  listeners.forEach((listener) => {
    listener({ matches } as MediaQueryListEvent)
  })
}

const mockMatchMedia = (matches: boolean) => {
  matchesState = matches
  listeners.clear()

  Object.defineProperty(window, 'matchMedia', {
    configurable: true,
    value: vi.fn().mockImplementation((query: string) => ({
      get matches() {
        return matchesState
      },
      media: query,
      onchange: null,
      addEventListener: vi.fn((event: string, listener: MatchMediaListener) => {
        if (event !== 'change') return
        listeners.add(listener)
      }),
      removeEventListener: vi.fn((event: string, listener: MatchMediaListener) => {
        if (event !== 'change') return
        listeners.delete(listener)
      }),
      addListener: vi.fn((listener: MatchMediaListener) => {
        listeners.add(listener)
      }),
      removeListener: vi.fn((listener: MatchMediaListener) => {
        listeners.delete(listener)
      }),
      dispatchEvent: vi.fn(),
    })),
  })
}

const renderApp = () =>
  renderComponent(
    {
      template: '<div id="app">Dummy</div>',
      setup() {
        useMobileDetection()

        return () => null
      },
    },
    {
      store: true,
    },
  )

describe('useMobileDetection', () => {
  beforeEach(() => {
    mockMatchMedia(false)
    notifyMock.mockReset()
    removeNotificationMock.mockReset()
  })

  it('removes the notification immediately on non-mobile screen size', async () => {
    renderApp()

    await waitFor(() => {
      expect(removeNotificationMock).toHaveBeenCalledWith('mobile-screen-size')
    })

    expect(notifyMock).not.toHaveBeenCalled()
  })

  it('shows a persistent warning notification on the smallest screen', async () => {
    mockMatchMedia(true)

    renderApp()

    await waitFor(() => {
      expect(notifyMock).toHaveBeenCalledWith({
        id: 'mobile-screen-size',
        type: NotificationTypes.Warn,
        message:
          "This screen size isn't fully supported for the desktop layout. For the best experience, switch to the mobile layout.",
        persistent: true,
      })
    })

    expect(removeNotificationMock).not.toHaveBeenCalled()
  })

  it('shows warning notification only once per session', async () => {
    renderApp()

    triggerMatchMediaChange(true)

    await waitFor(() => {
      expect(notifyMock).toHaveBeenCalledTimes(1)
    })

    triggerMatchMediaChange(false)

    await waitForNextTick()

    expect(removeNotificationMock).toHaveBeenCalledWith('mobile-screen-size')

    triggerMatchMediaChange(true)

    await waitForNextTick()

    expect(notifyMock).toHaveBeenCalledTimes(1)
  })
})
