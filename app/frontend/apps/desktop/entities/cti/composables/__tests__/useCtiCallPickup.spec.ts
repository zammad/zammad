// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { defineComponent, h } from 'vue'

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import renderComponent, { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { EnumCtiPickupView, type CtiCallPickupSubscription } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

import { CtiCallPickupDocument } from '../../graphql/subscriptions/ctiCallPickup.api.ts'
import { getCtiCallPickupSubscriptionHandler } from '../../graphql/subscriptions/ctiCallPickup.mocks.ts'
import { useCtiCallPickup } from '../useCtiCallPickup.ts'

import type { RouteRecordRaw } from 'vue-router'

const routerRoutes: RouteRecordRaw[] = [
  { path: '/', name: 'Dashboard', component: { template: 'dashboard' } },
  { path: '/users/:internalId(\\d+)', name: 'UserDetailView', component: { template: 'user' } },
  { path: '/tickets/create/:tabId?', name: 'TicketCreate', component: { template: 'create' } },
  { path: '/:pathMatch(.*)*', name: 'Error', component: { template: 'error' } },
]

// Lives in the app root, so a component hosts it here.
const Host = defineComponent({
  setup() {
    useCtiCallPickup()

    return () => h('div')
  },
})

const customer = {
  __typename: 'User' as const,
  id: convertToGraphQLId('User', 2),
  internalId: 2,
}

const log = {
  __typename: 'CtiLog' as const,
  id: convertToGraphQLId('Cti::Log', 1),
  from: '4912345678',
  fromPretty: '+49 12345678',
}

type PickupTarget = CtiCallPickupSubscription['ctiCallPickup']['target']

const pushTarget = (target: DeepPartial<PickupTarget>) =>
  getCtiCallPickupSubscriptionHandler().trigger({
    ctiCallPickup: { __typename: 'CtiCallPickupPayload', target },
  })

let visibilityState: DocumentVisibilityState = 'visible'
let restoreVisibility = () => {}

// The visibility composable reads the state off the document and follows its change event.
const setDocumentVisibility = (state: DocumentVisibilityState) => {
  visibilityState = state
  document.dispatchEvent(new Event('visibilitychange'))
}

const renderHost = async (initialPath = '/') => {
  renderComponent(Host, { router: true, routerRoutes, store: true })

  const router = getTestRouter()

  await router.replace(initialPath)
  await waitForNextTick()

  vi.mocked(router.push).mockClear()
  vi.mocked(router.replace).mockClear()

  return router
}

describe('useCtiCallPickup', () => {
  beforeEach(() => {
    mockPermissions(['cti.agent', 'ticket.agent'])
    mockApplicationConfig({
      cti_integration: true,
      sipgate_integration: false,
      placetel_integration: false,
    })

    visibilityState = 'visible'

    const visibilitySpy = vi
      .spyOn(document, 'visibilityState', 'get')
      .mockImplementation(() => visibilityState)

    restoreVisibility = () => visibilitySpy.mockRestore()
  })

  afterEach(() => {
    restoreVisibility()
  })

  it('opens the detail view of the detected customer', async () => {
    const router = await renderHost()

    await pushTarget({ view: EnumCtiPickupView.UserDetail, customer, log })

    expect(router.push).toHaveBeenCalledWith({
      name: 'UserDetailView',
      params: { internalId: 2 },
    })
    expect(router.currentRoute.value.path).toBe('/users/2')
  })

  it('opens a ticket create tab carrying the detected customer', async () => {
    const router = await renderHost()

    await pushTarget({ view: EnumCtiPickupView.TicketCreate, customer, log })

    expect(router.push).toHaveBeenCalledWith({
      name: 'TicketCreate',
      query: { customer_id: 2 },
    })
  })

  it('opens a ticket create tab carrying the number when no customer was detected', async () => {
    const router = await renderHost()

    await pushTarget({ view: EnumCtiPickupView.TicketCreate, customer: null, log })

    expect(router.push).toHaveBeenCalledWith({
      name: 'TicketCreate',
      query: { customer_phone: '+49 12345678' },
    })
  })

  it('opens another create tab instead of reusing the one the agent is on', async () => {
    const router = await renderHost('/tickets/create/unsaved-tab')

    await pushTarget({ view: EnumCtiPickupView.TicketCreate, customer, log })

    expect(router.replace).not.toHaveBeenCalled()
    expect(router.currentRoute.value.params.tabId).not.toBe('unsaved-tab')
    expect(router.currentRoute.value.query).toEqual({ customer_id: '2' })
  })

  it('defers the target in a hidden browser tab until the agent turns to it', async () => {
    setDocumentVisibility('hidden')

    const router = await renderHost()

    await pushTarget({ view: EnumCtiPickupView.UserDetail, customer, log })

    expect(router.push).not.toHaveBeenCalled()

    setDocumentVisibility('visible')
    await waitForNextTick()

    expect(router.push).toHaveBeenCalledWith({
      name: 'UserDetailView',
      params: { internalId: 2 },
    })
  })

  it('opens only the latest of several deferred targets', async () => {
    setDocumentVisibility('hidden')

    const router = await renderHost()

    await pushTarget({ view: EnumCtiPickupView.UserDetail, customer, log })
    await pushTarget({ view: EnumCtiPickupView.TicketCreate, customer: null, log })

    setDocumentVisibility('visible')
    await waitForNextTick()

    expect(router.push).toHaveBeenCalledTimes(1)
    expect(router.push).toHaveBeenCalledWith({
      name: 'TicketCreate',
      query: { customer_phone: '+49 12345678' },
    })
  })

  it('forgets a deferred target after a minute', async () => {
    setDocumentVisibility('hidden')

    const router = await renderHost()

    vi.useFakeTimers()

    // The mock settles its trigger on a timer of its own, which the fake clock has to run.
    const pushing = pushTarget({ view: EnumCtiPickupView.UserDetail, customer, log })
    await vi.advanceTimersByTimeAsync(0)
    await pushing

    await vi.advanceTimersByTimeAsync(60_000)
    vi.useRealTimers()

    setDocumentVisibility('visible')
    await waitForNextTick()

    expect(router.push).not.toHaveBeenCalled()
    expect(router.currentRoute.value.path).toBe('/')
  })

  it('stays put while the subscription carries no target', async () => {
    const router = await renderHost()

    await pushTarget(null)

    expect(router.push).not.toHaveBeenCalled()
    expect(router.currentRoute.value.path).toBe('/')
  })

  it('does not subscribe without the cti.agent permission', async () => {
    mockPermissions(['ticket.agent'])

    await renderHost()

    expect(getCtiCallPickupSubscriptionHandler()).toBeUndefined()
    expect(getGraphQLMockCalls(CtiCallPickupDocument)).toHaveLength(0)
  })

  it('does not subscribe without the ticket.agent permission', async () => {
    mockPermissions(['cti.agent'])

    await renderHost()

    expect(getCtiCallPickupSubscriptionHandler()).toBeUndefined()
    expect(getGraphQLMockCalls(CtiCallPickupDocument)).toHaveLength(0)
  })

  it('does not subscribe without a CTI backend', async () => {
    mockApplicationConfig({
      cti_integration: false,
      sipgate_integration: false,
      placetel_integration: false,
    })

    await renderHost()

    expect(getCtiCallPickupSubscriptionHandler()).toBeUndefined()
    expect(getGraphQLMockCalls(CtiCallPickupDocument)).toHaveLength(0)
  })
})
