// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import type { ExtendedRenderResult } from '#tests/support/components/index.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import type { UserData } from '#shared/types/store.ts'

import NavigationMenu from '../NavigationMenu.vue'

const renderMenu = () => {
  return renderComponent(NavigationMenu, {
    props: {
      categories: [
        {
          label: 'Personal',
          id: 'category-personal',
          order: 10,
        },
        {
          label: 'Security',
          id: 'category-security',
          order: 20,
        },
      ],
      entries: {
        Personal: [
          {
            label: 'Downloads',
            keywords: 'Ačiū',
            route: { name: '' },
          },
          {
            label: 'Calls',
            keywords: 'Another,Keyword',
            route: { name: '' },
          },
        ],
        Security: [
          {
            label: 'Devices',
            route: { name: '' },
          },
          {
            label: 'Sessions',
            route: { name: '' },
          },
        ],
      },
    },
    router: true,
  })
}

describe('menu', () => {
  it('renders the menu', async () => {
    const view = renderMenu()

    expect(view.getByText('Personal')).toBeInTheDocument()
    expect(view.getByText('Downloads')).toBeInTheDocument()
    expect(view.getByText('Calls')).toBeInTheDocument()

    expect(view.getByText('Security')).toBeInTheDocument()
    expect(view.getByText('Devices')).toBeInTheDocument()
    expect(view.getByText('Sessions')).toBeInTheDocument()
  })

  it('supports collapsing sections', async () => {
    const view = renderMenu()
    const collapseButton = view.getAllByLabelText('Collapse this element').at(0)

    expect(view.queryByText('Personal')).toBeInTheDocument()

    await view.events.click(collapseButton as HTMLElement)

    expect(view.queryByText('Downloads')).not.toBeVisible()
    expect(view.queryByText('Calls')).not.toBeVisible()
  })
})

describe('menu filtering', () => {
  const filterBy = async (view: ExtendedRenderResult, input: string) => {
    view.getByText('apply filter').click()
    await waitForNextTick()
    await view.events.type(view.getByRole('searchbox'), input)
    await waitForNextTick()
  }

  it('filters the menu entries list', async () => {
    const view = renderMenu()

    await filterBy(view, 'es')

    expect(view.queryByText('Downloads')).not.toBeInTheDocument()
    expect(view.queryByText('Calls')).not.toBeInTheDocument()

    expect(view.queryByText('Devices')).toBeInTheDocument()
    expect(view.queryByText('Sessions')).toBeInTheDocument()
  })

  it('does not show categories when filtering', async () => {
    const view = renderMenu()

    await filterBy(view, 'es')

    expect(view.queryByText('Personal')).not.toBeInTheDocument()
    expect(view.queryByText('Security')).not.toBeInTheDocument()
  })

  it('filters the list by keyword', async () => {
    const view = renderMenu()

    await filterBy(view, 'Keyword')

    expect(view.queryByText('Calls')).toBeInTheDocument()

    expect(view.queryByText('Downloads')).not.toBeInTheDocument()
    expect(view.queryByText('Devices')).not.toBeInTheDocument()
    expect(view.queryByText('Sessions')).not.toBeInTheDocument()
  })

  it('allows any case and skips diacritics', async () => {
    const view = renderMenu()

    await filterBy(view, 'ąciu')

    expect(view.queryByText('Downloads')).toBeInTheDocument()

    expect(view.queryByText('Calls')).not.toBeInTheDocument()
    expect(view.queryByText('Devices')).not.toBeInTheDocument()
    expect(view.queryByText('Sessions')).not.toBeInTheDocument()
  })

  it('shows empty list if nothing matches the search', async () => {
    const view = renderMenu()

    await filterBy(view, 'nonexistantkeyword')

    expect(view.queryByText('Downloads')).not.toBeInTheDocument()
    expect(view.queryByText('Calls')).not.toBeInTheDocument()
    expect(view.queryByText('Devices')).not.toBeInTheDocument()
    expect(view.queryByText('Sessions')).not.toBeInTheDocument()
  })

  it('goes back to categorized view', async () => {
    const view = renderMenu()

    await filterBy(view, 'nonexistantkeyword')

    expect(view.queryByText('apply filter')).not.toBeInTheDocument()
    expect(view.queryByText('Personal')).not.toBeInTheDocument()

    view.getByLabelText('Clear filter').click()

    await waitForNextTick()

    expect(view.queryByText('apply filter')).toBeInTheDocument()
    expect(view.queryByText('Personal')).toBeInTheDocument()
  })
})

describe('menu entry visibility via "show"', () => {
  const renderMenuWithShowEntry = () => {
    return renderComponent(NavigationMenu, {
      props: {
        categories: [
          {
            label: 'Profile',
            id: 'category-profile',
            order: 1000,
          },
        ],
        entries: {
          Profile: [
            {
              category: {
                label: 'Profile',
                id: 'category-profile',
                order: 1000,
              },
              label: 'New BETA UI',
              route: {
                path: 'new-beta-ui',
                meta: {
                  requiredPermission: 'user_preferences.beta_ui_switch',
                },
              },
              show: (currentUser: Maybe<UserData>) =>
                currentUser?.hasBetaUiSwitchAvailable ?? false,
            },
          ],
        },
      },
      router: true,
    })
  }

  it('shows the entry when the current user satisfies its "show" condition', () => {
    mockUserCurrent({
      hasBetaUiSwitchAvailable: true,
    })

    mockPermissions(['user_preferences.beta_ui_switch'])

    const view = renderMenuWithShowEntry()

    expect(view.getByText('New BETA UI')).toBeInTheDocument()
  })

  it('hides the entry when the current user does not satisfy its "show" condition', () => {
    mockUserCurrent({
      hasBetaUiSwitchAvailable: false,
    })

    mockPermissions(['user_preferences.beta_ui_switch'])

    const view = renderMenuWithShowEntry()

    expect(view.queryByText('New BETA UI')).not.toBeInTheDocument()
  })

  it('hides the entry when the current user does have required permission', () => {
    mockUserCurrent({
      hasBetaUiSwitchAvailable: true,
    })

    const view = renderMenuWithShowEntry()

    expect(view.queryByText('New BETA UI')).not.toBeInTheDocument()
  })
})
