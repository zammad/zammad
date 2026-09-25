// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import renderComponent, { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import {
  mockUserAddMutation,
  waitForUserAddMutationCalls,
} from '#shared/entities/user/graphql/mutations/add.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { useSidebarDisplayStore } from '#desktop/components/layout/stores/sidebarDisplay.ts'
import { SidebarName } from '#desktop/components/layout/types.ts'
import type { PageRoute } from '#desktop/components/PageNavigation/navigationItems.ts'
import PageNavigation from '#desktop/components/PageNavigation/PageNavigation.vue'
import {
  mockUserInfoForPopoverQuery,
  waitForUserInfoForPopoverQueryCalls,
} from '#desktop/components/User/UserPopoverWithTrigger/graphql/queries/userInfoForPopover.mocks.ts'
import { waitForUserCurrentCallerNotificationUpdateMutationCalls } from '#desktop/entities/cti/graphql/mutations/userCurrentCallerNotificationUpdate.mocks.ts'
import {
  mockCtiSidebarQuery,
  waitForCtiSidebarQueryCalls,
} from '#desktop/entities/cti/graphql/queries/ctiSidebar.mocks.ts'

import ctiRoutes from '../routes.ts'

import {
  knownCustomer,
  mockUserCreateFlyoutQueries,
  ringingCallFromKnownCaller,
  ringingCallFromPossibleCaller,
  ringingCallFromPossibleCallers,
  ringingCallFromUnknownCaller,
} from './mocks/caller-log-mocks.ts'

import type { RingingCall } from '../types.ts'

const [ctiRoute] = ctiRoutes

const phone: PageRoute = {
  path: ctiRoute.path,
  name: ctiRoute.name as string,
  meta: ctiRoute.meta as PageRoute['meta'],
}

// The real caller log route, and only that one, as the navigation's item list.
vi.mock('#desktop/components/PageNavigation/navigationItems.ts', () => ({
  get navigationItems() {
    return [{ type: 'route', order: 400, route: phone }]
  },
  numberOfPermanentItems: 0,
}))

const routerRoutes = [
  { path: '/', name: 'Root', component: { template: 'root' } },
  { path: '/cti', name: 'CallerLog', component: { template: 'caller log' } },
  { path: '/tickets/create', name: 'TicketCreate', component: { template: 'ticket create' } },
  // The callers' `tel:` links pass through the router too, and warn without a catch-all.
  { path: '/:pathMatch(.*)*', name: 'Error', component: { template: 'error' } },
]

const mockSidebar = (unhandledCount: number, ringingCalls: RingingCall[] = []) =>
  mockCtiSidebarQuery({ ctiSidebar: { unhandledCount, ringingCalls } })

// The user mock resets the permissions, so they always follow it.
const mockCallerNotification = (enabled: boolean) => {
  mockUserCurrent({ personalSettings: { callerNotificationEnabled: enabled } })
  mockPermissions(['cti.agent'])
}

const waitForSidebar = async () => {
  await waitForCtiSidebarQueryCalls()
  await waitForNextTick()
}

const renderNavigation = (collapsed = false) =>
  renderComponent(PageNavigation, {
    router: true,
    routerRoutes,
    store: true,
    form: true,
    flyout: true,
    props: { collapsed },
  })

const getCallerEntry = async (view: ReturnType<typeof renderNavigation>, number: string) => {
  const list = within(await view.findByRole('list', { name: 'Ringing calls' }))

  return within(list.getByText(number).closest('li') as HTMLElement)
}

describe('caller log navigation entry', () => {
  beforeEach(() => {
    mockSidebar(3)
    mockCallerNotification(true)
    mockApplicationConfig({
      cti_integration: true,
      sipgate_integration: false,
      placetel_integration: false,
      user_name_format: 'first_last',
    })
  })

  // The collapsed state is persisted, so it would leak into the next example.
  afterEach(() => {
    localStorage.clear()
  })

  it.each([false, true])('has no accessibility violations (collapsed: %s)', async (collapsed) => {
    mockSidebar(3, [ringingCallFromKnownCaller, ringingCallFromUnknownCaller])

    const view = renderNavigation(collapsed)

    await waitForSidebar()

    await expect(view.container).toBeAccessible()
  })

  it('links to the caller log and shows the unhandled calls', async () => {
    const view = renderNavigation()

    const link = await view.findByRole('link', { name: 'Phone 3 unhandled calls' })

    expect(link).toHaveAttribute('href', '/desktop/cti')
    expect(link).toHaveTextContent('3')
    expect(view.getByIconName('telephone')).toBeInTheDocument()
  })

  it('shows no counter without unhandled calls', async () => {
    mockSidebar(0)

    const view = renderNavigation()

    await waitForSidebar()

    expect(view.getByRole('link', { name: 'Phone' })).toHaveTextContent(/^Phone$/)
  })

  it('caps the counter at 99+', async () => {
    mockSidebar(100)

    const view = renderNavigation()

    expect(await view.findByRole('link', { name: 'Phone 100 unhandled calls' })).toHaveTextContent(
      '99+',
    )
  })

  it('is absent without the cti.agent permission', () => {
    mockPermissions(['ticket.agent'])

    const view = renderNavigation()

    expect(view.queryByRole('link', { name: /Phone/ })).not.toBeInTheDocument()
  })

  it('is absent while no CTI backend is enabled', () => {
    mockApplicationConfig({
      cti_integration: false,
      sipgate_integration: false,
      placetel_integration: false,
    })

    const view = renderNavigation()

    expect(view.queryByRole('link', { name: /Phone/ })).not.toBeInTheDocument()
  })

  it('is present with any of the CTI backends enabled', () => {
    mockApplicationConfig({
      cti_integration: false,
      sipgate_integration: false,
      placetel_integration: true,
    })

    const view = renderNavigation()

    expect(view.getByRole('link', { name: /Phone/ })).toBeInTheDocument()
  })

  describe('on the caller log page', () => {
    afterEach(async () => {
      await getTestRouter().push('/')
    })

    it('highlights the entry and turns the counter white', async () => {
      const view = renderNavigation()

      const link = await view.findByRole('link', { name: 'Phone 3 unhandled calls' })

      await getTestRouter().push('/cti')

      expect(link).toHaveClass('bg-blue-800!')
      expect(view.getByText('3', { selector: '[aria-hidden]' }).parentElement).toHaveClass(
        'bg-white!',
      )
    })
  })

  describe('caller notification switch', () => {
    it('reflects the caller notification setting', () => {
      const view = renderNavigation()

      expect(view.getByRole('switch', { name: 'Caller notification' })).toHaveAttribute(
        'aria-checked',
        'true',
      )
    })

    it('toggles the setting without navigating', async () => {
      const view = renderNavigation()

      await view.events.click(view.getByRole('switch', { name: 'Caller notification' }))

      expect(view.getByRole('switch', { name: 'Caller notification' })).toHaveAttribute(
        'aria-checked',
        'false',
      )

      const calls = await waitForUserCurrentCallerNotificationUpdateMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({ enabled: false })
      expect(getTestRouter().push).not.toHaveBeenCalled()
      expect(getTestRouter().currentRoute.value.path).toBe('/')
    })

    it('toggles with the keyboard without navigating', async () => {
      const view = renderNavigation()

      const switcher = view.getByRole('switch', { name: 'Caller notification' })

      switcher.focus()
      await view.events.keyboard(' ')

      expect(switcher).toHaveAttribute('aria-checked', 'false')

      await view.events.keyboard('{Enter}')

      expect(switcher).toHaveAttribute('aria-checked', 'true')
      expect(getTestRouter().push).not.toHaveBeenCalled()
    })
  })

  describe('ringing calls', () => {
    beforeEach(() => {
      mockSidebar(2, [ringingCallFromKnownCaller, ringingCallFromUnknownCaller])
    })

    it('lists them below the entry with the caller and the number', async () => {
      const view = renderNavigation()

      const list = within(await view.findByRole('list', { name: 'Ringing calls' }))

      expect(list.getAllByRole('listitem')).toHaveLength(2)
      expect(list.getByRole('img', { name: 'Unknown caller' })).toBeInTheDocument()
      expect(list.getAllByLabelText('Ringing…')).toHaveLength(2)
      expect(list.getByText('Franz Bauer')).toBeInTheDocument()

      // The number is plain text here; only the caller log offers it as a callable link.
      expect(list.getByText('+49 30 609854180')).toBeInTheDocument()
      expect(list.queryByRole('link', { name: '+49 30 609854180' })).not.toBeInTheDocument()
    })

    it('announces the status of a call, which is shown as a tooltip', async () => {
      const view = renderNavigation()

      const list = within(await view.findByRole('list', { name: 'Ringing calls' }))

      expect(list.getAllByLabelText('Ringing…')[0]).toHaveAttribute('aria-hidden', 'false')
    })

    it('names the maybe badge, which is reduced to its icon here', async () => {
      mockSidebar(1, [ringingCallFromPossibleCaller])

      const view = renderNavigation()

      const list = within(await view.findByRole('list', { name: 'Ringing calls' }))

      expect(list.getByRole('img', { name: 'Maybe' })).toBeInTheDocument()
      expect(list.queryByText('Maybe')).not.toBeInTheDocument()
    })

    // An unknown caller gets the same ticket as a pickup of the call: the number stands in for
    //   the customer, so the ticket does not have to wait for the user to be created first.
    it('offers an unknown caller as a new user, and a new ticket carrying the number', async () => {
      mockPermissions(['cti.agent', 'ticket.agent'])

      const view = renderNavigation()

      const entry = await getCallerEntry(view, '+49 12345678')

      expect(entry.getByRole('link', { name: 'New user' })).toBeInTheDocument()
      expect(entry.queryByRole('button', { name: 'New user' })).not.toBeInTheDocument()

      await view.events.click(entry.getByRole('button', { name: 'New ticket' }))

      expect(getTestRouter().push).toHaveBeenCalledWith({
        name: 'TicketCreate',
        query: { customer_phone: '+49 12345678' },
      })
    })

    it('prefills the number of an unknown caller in the user create flyout', async () => {
      mockPermissions(['cti.agent', 'ticket.agent'])
      mockUserCreateFlyoutQueries()

      const view = renderNavigation()

      const entry = await getCallerEntry(view, '+49 12345678')

      await view.events.click(entry.getByRole('link', { name: 'New user' }))

      const flyout = await view.findByRole('complementary', { name: 'New user' })

      expect(await within(flyout).findByLabelText('Phone')).toHaveValue('+49 12345678')
    })

    it('opens a new ticket for the created user, prefilled as its customer', async () => {
      mockPermissions(['cti.agent', 'ticket.agent'])
      mockUserCreateFlyoutQueries()
      mockUserAddMutation({
        userAdd: { user: { id: convertToGraphQLId('User', 42), internalId: 42 }, errors: null },
      })

      const view = renderNavigation()

      const entry = await getCallerEntry(view, '+49 12345678')

      await view.events.click(entry.getByRole('link', { name: 'New user' }))

      const flyout = await view.findByRole('complementary', { name: 'New user' })

      expect(await within(flyout).findByLabelText('Phone')).toHaveValue('+49 12345678')

      await view.events.click(within(flyout).getByRole('button', { name: 'Create' }))

      await waitForUserAddMutationCalls()

      expect(getTestRouter().push).toHaveBeenCalledWith({
        name: 'TicketCreate',
        query: { customer_id: 42 },
      })
    })

    // Creating a user needs ticket or user permissions, which a phone agent may lack.
    it('does not offer creating a user to a phone agent without ticket permissions', async () => {
      const view = renderNavigation()

      const list = within(await view.findByRole('list', { name: 'Ringing calls' }))

      expect(list.getByRole('img', { name: 'Unknown caller' })).toBeInTheDocument()
      expect(list.queryByRole('link', { name: 'New user' })).not.toBeInTheDocument()
    })

    it('opens a new ticket for a known caller, and offers no new user', async () => {
      mockPermissions(['cti.agent', 'ticket.agent'])

      const view = renderNavigation()

      const entry = await getCallerEntry(view, '+49 30 609854180')

      expect(entry.queryByRole('link', { name: 'New user' })).not.toBeInTheDocument()

      await view.events.click(entry.getByRole('button', { name: 'New ticket' }))

      expect(getTestRouter().push).toHaveBeenCalledWith({
        name: 'TicketCreate',
        query: { customer_id: 2 },
      })
    })

    it('opens a new ticket from the keyboard', async () => {
      mockPermissions(['cti.agent', 'ticket.agent'])

      const view = renderNavigation()

      const entry = await getCallerEntry(view, '+49 30 609854180')

      entry.getByRole('button', { name: 'New ticket' }).focus()
      await view.events.keyboard('{Enter}')

      expect(getTestRouter().push).toHaveBeenCalledWith({
        name: 'TicketCreate',
        query: { customer_id: 2 },
      })
    })

    // The first match is the customer a pickup of the call lands on as well.
    it('opens a new ticket for the first of several possible callers', async () => {
      mockPermissions(['cti.agent', 'ticket.agent'])
      mockSidebar(1, [ringingCallFromPossibleCallers])

      const view = renderNavigation()

      const entry = await getCallerEntry(view, '+49 30 456646543')

      expect(entry.getByText('+2')).toBeInTheDocument()
      expect(entry.queryByRole('link', { name: 'New user' })).not.toBeInTheDocument()

      await view.events.click(entry.getByRole('button', { name: 'New ticket' }))

      expect(getTestRouter().push).toHaveBeenCalledWith({
        name: 'TicketCreate',
        query: { customer_id: 3 },
      })
    })

    // A user admin may create the user, but cannot open the ticket create screen.
    it('offers a user admin without ticket permissions a new user, and no new ticket', async () => {
      mockPermissions(['cti.agent', 'admin.user'])

      const view = renderNavigation()

      const list = within(await view.findByRole('list', { name: 'Ringing calls' }))

      expect(list.getByRole('link', { name: 'New user' })).toBeInTheDocument()
      expect(list.queryByRole('button', { name: 'New ticket' })).not.toBeInTheDocument()
    })

    it('does not offer a new ticket to a phone agent without ticket permissions', async () => {
      const view = renderNavigation()

      const list = within(await view.findByRole('list', { name: 'Ringing calls' }))

      expect(list.getByText('Franz Bauer')).toBeInTheDocument()
      expect(list.getByRole('img', { name: 'Unknown caller' })).toBeInTheDocument()
      expect(list.queryByRole('button', { name: 'New ticket' })).not.toBeInTheDocument()
    })

    it('is hidden while the caller notification is off, counter included', async () => {
      mockCallerNotification(false)

      const view = renderNavigation()

      await waitForSidebar()

      expect(view.queryByRole('list', { name: 'Ringing calls' })).not.toBeInTheDocument()
      expect(view.getByRole('link', { name: 'Phone' })).toBeInTheDocument()
      expect(view.queryByText('2 unhandled calls')).not.toBeInTheDocument()
    })

    it('appears as soon as the caller notification is switched on', async () => {
      mockCallerNotification(false)

      const view = renderNavigation()

      await waitForSidebar()

      await view.events.click(view.getByRole('switch', { name: 'Caller notification' }))

      expect(await view.findByRole('list', { name: 'Ringing calls' })).toBeInTheDocument()
    })

    describe('caller popover', () => {
      beforeEach(() => {
        mockPermissions(['cti.agent', 'ticket.agent'])
        mockUserInfoForPopoverQuery({ user: knownCustomer })
      })

      it('opens the popover of a detected customer on hover', async () => {
        const view = renderNavigation()

        const entry = await getCallerEntry(view, '+49 30 609854180')

        await view.events.hover(entry.getByRole('img', { name: 'Avatar (Franz Bauer)' }))

        const calls = await waitForUserInfoForPopoverQueryCalls()

        expect(calls.at(-1)?.variables).toEqual({
          userId: knownCustomer.id,
          secondaryOrganizationsCount: 5,
        })

        const popover = await view.findByRole('region')

        expect(await within(popover).findByText('Franz Bauer')).toBeVisible()
      })

      it('opens the popover of a detected customer from the keyboard', async () => {
        const view = renderNavigation()

        const entry = await getCallerEntry(view, '+49 30 609854180')
        const trigger = entry.getByRole('link', { name: 'Avatar (Franz Bauer)' })

        trigger.focus()
        await view.events.keyboard(' ')

        expect(trigger).toHaveAttribute('aria-expanded', 'true')
        expect(await view.findByRole('region')).toBeInTheDocument()
      })

      it('has no popover for an unknown caller', async () => {
        const view = renderNavigation()

        const entry = await getCallerEntry(view, '+49 12345678')

        expect(entry.queryByRole('img', { name: /^Avatar \(/ })).not.toBeInTheDocument()
        expect(entry.queryByRole('link', { expanded: false })).not.toBeInTheDocument()
      })

      // Its popover query needs `UserPolicy#show?`, which a phone agent without ticket permissions lacks.
      it('shows the detected customer without a popover to a phone agent without ticket permissions', async () => {
        mockPermissions(['cti.agent'])

        const view = renderNavigation()

        const entry = await getCallerEntry(view, '+49 30 609854180')

        expect(entry.getByRole('img', { name: 'Avatar (Franz Bauer)' })).toBeInTheDocument()
        expect(entry.queryByRole('link', { expanded: false })).not.toBeInTheDocument()
      })
    })
  })

  describe('collapsed sidebar', () => {
    it('shows an icon with a dot for unhandled calls and no switch', async () => {
      mockSidebar(3, [ringingCallFromKnownCaller])

      const view = renderNavigation(true)

      const dot = (await view.findByText('3 unhandled calls')).parentElement as HTMLElement
      const button = view.getByLabelText('Phone')

      expect(button).toHaveAttribute('aria-describedby', dot.id)
      expect(dot).toHaveAttribute('data-test-id', 'common-badge')
      expect(view.getByIconName('telephone')).toBeInTheDocument()
      expect(view.queryByRole('switch')).not.toBeInTheDocument()
    })

    it('reduces a ringing call to the avatar of its caller', async () => {
      mockSidebar(2, [ringingCallFromKnownCaller, ringingCallFromUnknownCaller])

      const view = renderNavigation(true)

      const list = within(await view.findByRole('list', { name: 'Ringing calls' }))

      expect(
        list.getByRole('button', { name: 'Ringing call from Franz Bauer' }),
      ).toBeInTheDocument()
      expect(
        list.getByRole('button', { name: 'Ringing call from unknown caller +49 12345678' }),
      ).toBeInTheDocument()
      expect(view.queryByRole('link', { name: '+49 30 609854180' })).not.toBeInTheDocument()
    })

    it('expands the sidebar instead of navigating when a caller is clicked', async () => {
      mockSidebar(3, [ringingCallFromKnownCaller])

      const sidebar = useSidebarDisplayStore()
      sidebar.setCollapsed(SidebarName.Primary, true)
      expect(sidebar.currentCollapsed[SidebarName.Primary]).toBe(true)

      const view = renderNavigation(true)

      await view.events.click(
        await view.findByRole('button', { name: 'Ringing call from Franz Bauer' }),
      )

      expect(getTestRouter().push).not.toHaveBeenCalled()
      expect(sidebar.currentCollapsed[SidebarName.Primary]).toBe(false)
    })

    it('shows no dot without unhandled calls', async () => {
      mockSidebar(0)

      const view = renderNavigation(true)

      await waitForSidebar()

      expect(view.getByLabelText('Phone')).not.toHaveAttribute('aria-describedby')
    })

    it('opens the caller log on click, a ringing call included', async () => {
      mockSidebar(3, [ringingCallFromKnownCaller])

      const sidebar = useSidebarDisplayStore()
      sidebar.setCollapsed(SidebarName.Primary, true)

      const view = renderNavigation(true)

      await waitForSidebar()
      await view.events.click(view.getByLabelText('Phone'))

      expect(getTestRouter().push).toHaveBeenCalledWith('/cti')
      expect(sidebar.currentCollapsed[SidebarName.Primary]).toBe(true)
    })
  })
})
