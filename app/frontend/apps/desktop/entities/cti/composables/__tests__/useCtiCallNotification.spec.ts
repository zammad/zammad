// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { defineComponent, h } from 'vue'

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import renderComponent, { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { resetGlobalStates } from '#tests/support/mock-globalState.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import {
  holdLockFromAnotherTab,
  mockWebLocks,
  unmockWebLocks,
} from '#tests/support/mock-webLocks.ts'
import { nullableMock, waitForNextTick, waitUntil } from '#tests/support/utils.ts'

import type { CtiSidebarQuery, CtiSidebarUpdatesSubscription } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import emitter from '#shared/utils/emitter.ts'

import { BROWSER_NOTIFICATION_LOCK } from '#desktop/composables/useBrowserNotification.ts'

import { CtiSidebarDocument } from '../../graphql/queries/ctiSidebar.api.ts'
import {
  mockCtiSidebarQuery,
  waitForCtiSidebarQueryCalls,
} from '../../graphql/queries/ctiSidebar.mocks.ts'
import { getCtiSidebarUpdatesSubscriptionHandler } from '../../graphql/subscriptions/ctiSidebarUpdates.mocks.ts'
import { useCtiCallNotification } from '../useCtiCallNotification.ts'

import type { RouteRecordRaw } from 'vue-router'

type RingingCall = CtiSidebarQuery['ctiSidebar']['ringingCalls'][number]

// The shared browser notification instance snapshots the permission when it is
//   created, so every example gets a fresh one.
vi.mock('@vueuse/core', async (importOriginal) => ({
  ...(await importOriginal<typeof import('@vueuse/core')>()),
  createGlobalState: (await import('#tests/support/mock-globalState.ts')).createGlobalState,
}))

const routerRoutes: RouteRecordRaw[] = [
  { path: '/', name: 'Dashboard', component: { template: 'dashboard' } },
  { path: '/cti', name: 'CallerLog', component: { template: 'caller log' } },
  { path: '/:pathMatch(.*)*', name: 'Error', component: { template: 'error' } },
]

// Lives in the app root, so a component hosts it here.
const Host = defineComponent({
  setup() {
    useCtiCallNotification()

    return () => h('div')
  },
})

// Records what the notifier creates; the global stub of the test setup drops the arguments.
class NotificationStub {
  static permission: NotificationPermission = 'granted'

  static requestPermission = () => Promise.resolve('granted' as NotificationPermission)

  static instances: NotificationStub[] = []

  close = vi.fn()

  onclick: (() => void) | null = null

  constructor(
    public title: string,
    public options?: NotificationOptions,
  ) {
    // VueUse probes the support with an empty notification.
    if (title) NotificationStub.instances.push(this)
  }
}

const inboundCall: RingingCall = {
  __typename: 'CtiLog',
  id: convertToGraphQLId('Cti::Log', 1),
  direction: 'in',
  state: 'newCall',
  comment: null,
  from: '4930609854180',
  fromPretty: '+49 30 609854180',
  fromComment: 'Anna Lena',
  to: '4930609811111',
  toComment: 'Support',
  done: false,
  createdAt: '2026-09-21T09:00:00Z',
  fromMatches: [],
}

const anotherInboundCall: RingingCall = {
  ...inboundCall,
  id: convertToGraphQLId('Cti::Log', 2),
  from: '4930609854181',
  fromPretty: '+49 30 609854181',
  fromComment: 'Bob Smith',
}

const laterInboundCall: RingingCall = {
  ...inboundCall,
  id: convertToGraphQLId('Cti::Log', 4),
  from: '4930609854182',
  fromPretty: '+49 30 609854182',
  fromComment: 'Carla Weber',
}

const outboundCall: RingingCall = {
  ...inboundCall,
  id: convertToGraphQLId('Cti::Log', 3),
  direction: 'out',
}

const mockSidebar = (ringingCalls: RingingCall[] = []) =>
  mockCtiSidebarQuery({ ctiSidebar: { unhandledCount: 0, ringingCalls } })

const pushRingingCalls = async (ringingCalls: RingingCall[]) => {
  await getCtiSidebarUpdatesSubscriptionHandler().trigger(
    nullableMock<CtiSidebarUpdatesSubscription>({
      ctiSidebarUpdates: {
        __typename: 'CtiSidebarUpdatesPayload',
        sidebar: { __typename: 'CtiSidebar', unhandledCount: 0, ringingCalls },
      },
    }),
  )
  await waitForNextTick()
}

// The user mock resets the permissions, so they always follow it.
const mockCallerNotification = (enabled: boolean) => {
  mockUserCurrent({ personalSettings: { callerNotificationEnabled: enabled } })
  mockPermissions(['cti.agent'])
}

const setCallerNotification = async (enabled: boolean) => {
  const session = useSessionStore()

  session.user!.personalSettings = {
    ...session.user!.personalSettings!,
    callerNotificationEnabled: enabled,
  }

  await waitForNextTick()
}

const setWindowFocus = (focused: boolean) => {
  vi.spyOn(document, 'hasFocus').mockReturnValue(focused)
}

const renderHost = async (ringingCalls: RingingCall[] = []) => {
  mockSidebar(ringingCalls)

  const view = renderComponent(Host, { router: true, routerRoutes, store: true })

  await waitForCtiSidebarQueryCalls()
  await waitForNextTick()

  return view
}

describe('useCtiCallNotification', () => {
  beforeEach(() => {
    resetGlobalStates()
    vi.stubGlobal('Notification', NotificationStub)
    NotificationStub.permission = 'granted'
    NotificationStub.instances = []

    setWindowFocus(false)
    mockCallerNotification(true)
    mockApplicationConfig({
      cti_integration: true,
      sipgate_integration: false,
      placetel_integration: false,
    })
  })

  afterEach(() => {
    vi.unstubAllGlobals()
    unmockWebLocks()
  })

  it('shows a silent notification for a new inbound ringing call while the window is unfocused', async () => {
    await renderHost()

    await pushRingingCalls([inboundCall])

    expect(NotificationStub.instances).toHaveLength(1)

    const [notification] = NotificationStub.instances

    expect(notification.title).toBe('Call from Anna Lena for Support')
    expect(notification.options).toMatchObject({ silent: true, tag: inboundCall.id })
  })

  it('shows one notification per new inbound call', async () => {
    await renderHost()

    await pushRingingCalls([inboundCall])
    await pushRingingCalls([inboundCall, anotherInboundCall])

    expect(NotificationStub.instances.map((notification) => notification.title)).toEqual([
      'Call from Anna Lena for Support',
      'Call from Bob Smith for Support',
    ])
  })

  it('shows none for an outbound call', async () => {
    await renderHost()

    await pushRingingCalls([outboundCall])

    expect(NotificationStub.instances).toHaveLength(0)
  })

  it('shows none while the window is focused', async () => {
    setWindowFocus(true)

    await renderHost()

    await pushRingingCalls([inboundCall])

    expect(NotificationStub.instances).toHaveLength(0)
  })

  it('shows none while the caller notification is off', async () => {
    mockCallerNotification(false)

    await renderHost()

    await pushRingingCalls([inboundCall])

    expect(NotificationStub.instances).toHaveLength(0)
  })

  it.each(['default', 'denied'] as const)(
    'shows none without the browser permission (%s)',
    async (permission) => {
      NotificationStub.permission = permission

      await renderHost()

      await pushRingingCalls([inboundCall])

      expect(NotificationStub.instances).toHaveLength(0)
    },
  )

  it('does not query without the CTI permission', async () => {
    mockPermissions([])
    mockSidebar()

    renderComponent(Host, { router: true, routerRoutes, store: true })

    await waitForNextTick()

    expect(getGraphQLMockCalls(CtiSidebarDocument)).toHaveLength(0)
    expect(NotificationStub.instances).toHaveLength(0)
  })

  it('shows none for calls already ringing in the first result', async () => {
    await renderHost([inboundCall])

    expect(NotificationStub.instances).toHaveLength(0)

    // A call ringing after that is new.
    await pushRingingCalls([inboundCall, anotherInboundCall])

    expect(NotificationStub.instances).toHaveLength(1)
    expect(NotificationStub.instances[0].options).toMatchObject({ tag: anotherInboundCall.id })
  })

  it('shows none for a call ringing while the caller notification is switched on', async () => {
    mockCallerNotification(false)

    await renderHost([inboundCall])

    await setCallerNotification(true)

    expect(NotificationStub.instances).toHaveLength(0)

    await pushRingingCalls([inboundCall, anotherInboundCall])

    expect(NotificationStub.instances).toHaveLength(1)
    expect(NotificationStub.instances[0].options).toMatchObject({ tag: anotherInboundCall.id })
  })

  it('shows none for calls ringing in the list refetched after a reconnect', async () => {
    await renderHost()

    await pushRingingCalls([inboundCall])

    expect(NotificationStub.instances).toHaveLength(1)

    // A call that started ringing during the outage.
    mockSidebar([inboundCall, anotherInboundCall])
    emitter.emit('reconnected')

    await waitUntil(() => getGraphQLMockCalls(CtiSidebarDocument).length === 2)
    await waitForNextTick()

    expect(NotificationStub.instances).toHaveLength(1)

    await pushRingingCalls([inboundCall, anotherInboundCall, laterInboundCall])

    expect(NotificationStub.instances).toHaveLength(2)
    expect(NotificationStub.instances[1].options).toMatchObject({ tag: laterInboundCall.id })
  })

  it('shows one for a call ringing after a reconnect that left the list unchanged', async () => {
    await renderHost()

    emitter.emit('reconnected')

    await waitUntil(() => getGraphQLMockCalls(CtiSidebarDocument).length === 2)
    await waitForNextTick()

    await pushRingingCalls([inboundCall])

    expect(NotificationStub.instances).toHaveLength(1)
    expect(NotificationStub.instances[0].options).toMatchObject({ tag: inboundCall.id })
  })

  it('closes the notification when the call stops ringing', async () => {
    await renderHost()

    await pushRingingCalls([inboundCall, anotherInboundCall])

    const [first, second] = NotificationStub.instances

    await pushRingingCalls([anotherInboundCall])

    expect(first.close).toHaveBeenCalledOnce()
    expect(second.close).not.toHaveBeenCalled()
  })

  it('leaves the notifications to the tab the agent used last', async () => {
    mockWebLocks()

    const otherTab = holdLockFromAnotherTab(BROWSER_NOTIFICATION_LOCK)

    await renderHost()

    await pushRingingCalls([inboundCall])

    expect(NotificationStub.instances).toHaveLength(0)

    // The other tab is closed, so the next call is this tab's to notify about.
    otherTab.release()
    await waitForNextTick(true)

    await pushRingingCalls([inboundCall, anotherInboundCall])

    expect(NotificationStub.instances.map((notification) => notification.title)).toEqual([
      'Call from Bob Smith for Support',
    ])
  })

  it('closes its notifications when another tab takes over', async () => {
    mockWebLocks()

    await renderHost()

    await pushRingingCalls([inboundCall])

    const [notification] = NotificationStub.instances

    holdLockFromAnotherTab(BROWSER_NOTIFICATION_LOCK, true)
    await waitForNextTick(true)

    expect(notification.close).toHaveBeenCalledOnce()

    await pushRingingCalls([inboundCall, anotherInboundCall])

    expect(NotificationStub.instances).toHaveLength(1)
  })

  it('closes all notifications when the window gets focus', async () => {
    await renderHost()

    await pushRingingCalls([inboundCall, anotherInboundCall])

    window.dispatchEvent(new Event('focus'))

    NotificationStub.instances.forEach((notification) => {
      expect(notification.close).toHaveBeenCalledOnce()
    })

    // Closed once is enough when the call stops ringing afterwards.
    await pushRingingCalls([])

    NotificationStub.instances.forEach((notification) => {
      expect(notification.close).toHaveBeenCalledOnce()
    })
  })

  it('closes all notifications when the host goes away', async () => {
    const view = await renderHost()

    await pushRingingCalls([inboundCall, anotherInboundCall])

    view.unmount()

    NotificationStub.instances.forEach((notification) => {
      expect(notification.close).toHaveBeenCalledOnce()
    })
  })

  it.each([
    {
      caller: { fromComment: null },
      callee: { toComment: null },
      title: 'Call from 4930609854180 for 4930609811111',
    },
    {
      caller: { fromComment: 'Anna Lena' },
      callee: { toComment: null },
      title: 'Call from Anna Lena for 4930609811111',
    },
    {
      caller: { fromComment: null },
      callee: { toComment: 'Support' },
      title: 'Call from 4930609854180 for Support',
    },
  ])('falls back to the number without a comment: $title', async ({ caller, callee, title }) => {
    await renderHost()

    await pushRingingCalls([{ ...inboundCall, ...caller, ...callee }])

    expect(NotificationStub.instances[0].title).toBe(title)
  })

  it('focuses the window and opens the caller log on click', async () => {
    const focusSpy = vi.spyOn(window, 'focus').mockImplementation(() => {})

    await renderHost()

    const router = getTestRouter()

    await pushRingingCalls([inboundCall])

    const [notification] = NotificationStub.instances

    notification.onclick?.()

    expect(focusSpy).toHaveBeenCalledOnce()
    expect(router.push).toHaveBeenCalledWith({ name: 'CallerLog' })
    expect(notification.close).toHaveBeenCalledOnce()
  })
})
