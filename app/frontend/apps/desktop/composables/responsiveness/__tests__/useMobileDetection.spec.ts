// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'

import { renderComponent } from '#tests/support/components/index.ts'

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

const mockMatchMedia = (matches: boolean) => {
  Object.defineProperty(window, 'matchMedia', {
    configurable: true,
    value: vi.fn().mockImplementation((query: string) => ({
      matches,
      media: query,
      onchange: null,
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
      addListener: vi.fn(),
      removeListener: vi.fn(),
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
})
