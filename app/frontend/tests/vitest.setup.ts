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
