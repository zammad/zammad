// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import '@testing-library/jest-dom'
import { configure } from '@testing-library/vue'

// eslint-disable-next-line no-underscore-dangle
global.__ = (source) => {
  return source
}

configure({
  testIdAttribute: 'data-test-id',
})

require.extensions['.css'] = () => ({})

vi.stubGlobal('scrollTo', vi.fn())

vi.mock('@shared/components/CommonNotifications/composable', async () => {
  const { default: originalUseNotifications } = await vi.importActual<any>(
    '@shared/components/CommonNotifications/composable',
  )
  let notifications: any
  const useNotifications = () => {
    if (notifications) return notifications
    const result = originalUseNotifications()
    notifications = {
      notify: vi.fn(result.notify),
      notifications: result.notifications,
      removeNotification: vi.fn(result.removeNotification),
      clearAllNotifications: vi.fn(result.clearAllNotifications),
      hasErrors: vi.fn(result.hasErrors),
    }
    return notifications
  }

  return {
    default: useNotifications,
  }
})

// mock vueuse because of CommonDialog, it uses usePointerSwipe
// that is not supported in JSDOM
vi.mock('@vueuse/core', async () => {
  const mod = await vi.importActual<typeof import('@vueuse/core')>(
    '@vueuse/core',
  )
  return {
    ...mod,
    usePointerSwipe: vi
      .fn()
      .mockReturnValue({ distanceY: 0, isSwiping: false }),
  }
})

beforeEach((context) => {
  context.skipConsole = false

  if (!vi.isMockFunction(console.warn)) {
    vi.spyOn(console, 'warn').mockClear()
  } else {
    vi.mocked(console.warn).mockClear()
  }

  if (!vi.isMockFunction(console.error)) {
    vi.spyOn(console, 'error').mockClear()
  } else {
    vi.mocked(console.error).mockClear()
  }
})

afterEach((context) => {
  // we don't import it from `renderComponent`, because it may renderComponent may not be called
  // and it doesn't make sense to import everything from it
  if ('cleanupComponents' in globalThis) {
    globalThis.cleanupComponents()
  }

  if (context.skipConsole !== true) {
    expect(
      console.warn,
      'there were no warning during test',
    ).not.toHaveBeenCalled()
    expect(
      console.error,
      'there were no errors during test',
    ).not.toHaveBeenCalled()
  }
})

declare module 'vitest' {
  interface TestContext {
    skipConsole: boolean
  }
}

declare global {
  function cleanupComponents(): void
}
