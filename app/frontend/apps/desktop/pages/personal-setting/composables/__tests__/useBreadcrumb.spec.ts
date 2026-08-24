// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useBreadcrumb } from '../useBreadcrumb.ts'

const mockRoute = { name: '' }

vi.mock('vue-router', async () => ({
  ...(await vi.importActual<typeof import('vue-router')>('vue-router')),
  useRoute: () => mockRoute,
}))

describe('useBreadcrumb', () => {
  it.each([
    { route: 'PersonalSettingAppearance', category: 'Profile', label: 'Appearance' },
    { route: 'PersonalSettingPassword', category: 'Security', label: 'Password' },
    { route: 'PersonalSettingCalendar', category: 'Tickets', label: 'Calendar' },
  ])('derives category and label of $route from its plugin', ({ route, category, label }) => {
    mockRoute.name = route

    const { breadcrumbItems } = useBreadcrumb()

    // The category has no route, so it renders as plain text instead of a link.
    expect(breadcrumbItems.value).toEqual([{ label: category }, { label }])
  })

  it('has no items for a route without a plugin', () => {
    mockRoute.name = 'PersonalSettingUnknown'

    const { breadcrumbItems } = useBreadcrumb()

    expect(breadcrumbItems.value).toEqual([])
  })
})
