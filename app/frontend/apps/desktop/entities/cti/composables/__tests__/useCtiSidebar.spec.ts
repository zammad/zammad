// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { effectScope, type EffectScope } from 'vue'

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import { nullableMock, waitForNextTick, waitUntil } from '#tests/support/utils.ts'

import type { CtiSidebarUpdatesSubscription } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import emitter from '#shared/utils/emitter.ts'

import { CtiSidebarDocument } from '../../graphql/queries/ctiSidebar.api.ts'
import {
  mockCtiSidebarQuery,
  waitForCtiSidebarQueryCalls,
} from '../../graphql/queries/ctiSidebar.mocks.ts'
import { CtiSidebarUpdatesDocument } from '../../graphql/subscriptions/ctiSidebarUpdates.api.ts'
import { getCtiSidebarUpdatesSubscriptionHandler } from '../../graphql/subscriptions/ctiSidebarUpdates.mocks.ts'
import { useCtiSidebar } from '../useCtiSidebar.ts'

const ringingCall = {
  __typename: 'CtiLog' as const,
  id: convertToGraphQLId('Cti::Log', 1),
  direction: 'in',
  state: 'newCall',
  comment: null,
  from: '4930609854180',
  fromPretty: '+49 30 609854180',
  done: false,
  createdAt: '2026-09-21T09:00:00Z',
  fromMatches: [],
}

const mockSidebar = () =>
  mockCtiSidebarQuery({ ctiSidebar: { unhandledCount: 3, ringingCalls: [ringingCall] } })

// The user mock resets the permissions, so they always follow it.
const mockCallerNotification = (enabled: boolean) => {
  mockUserCurrent({ personalSettings: { callerNotificationEnabled: enabled } })
  mockPermissions(['cti.agent'])
}

const pushSidebar = (sidebar: CtiSidebarUpdatesSubscription['ctiSidebarUpdates']['sidebar']) =>
  getCtiSidebarUpdatesSubscriptionHandler().trigger(
    nullableMock<CtiSidebarUpdatesSubscription>({
      ctiSidebarUpdates: { __typename: 'CtiSidebarUpdatesPayload', sidebar },
    }),
  )

describe('useCtiSidebar', () => {
  let scope: EffectScope

  beforeEach(() => {
    scope = effectScope()
    mockCallerNotification(true)
    mockApplicationConfig({
      cti_integration: true,
      sipgate_integration: false,
      placetel_integration: false,
    })
  })

  afterEach(() => {
    scope.stop()
  })

  it('reads the counter and the ringing calls', async () => {
    await scope.run(async () => {
      mockSidebar()

      const { isLoaded, unhandledCount, ringingCalls } = useCtiSidebar()

      expect(isLoaded.value).toBe(false)

      await waitForCtiSidebarQueryCalls()
      await waitForNextTick()

      expect(isLoaded.value).toBe(true)
      expect(unhandledCount.value).toBe(3)
      expect(ringingCalls.value).toEqual([expect.objectContaining({ id: ringingCall.id })])
    })
  })

  it('hides the counter and the ringing calls while the caller notification is off', async () => {
    mockCallerNotification(false)

    await scope.run(async () => {
      mockSidebar()

      const { unhandledCount, ringingCalls, isNotificationEnabled } = useCtiSidebar()

      await waitForCtiSidebarQueryCalls()
      await waitForNextTick()

      expect(isNotificationEnabled.value).toBe(false)
      expect(unhandledCount.value).toBeUndefined()
      expect(ringingCalls.value).toEqual([])
    })
  })

  it('does not query without a CTI backend', async () => {
    mockApplicationConfig({
      cti_integration: false,
      sipgate_integration: false,
      placetel_integration: false,
    })

    await scope.run(async () => {
      const { isIntegrationEnabled, unhandledCount } = useCtiSidebar()

      await waitForNextTick()

      expect(isIntegrationEnabled.value).toBe(false)
      expect(unhandledCount.value).toBeUndefined()
      expect(getGraphQLMockCalls(CtiSidebarDocument)).toHaveLength(0)
    })
  })

  it('does not query without the CTI permission', async () => {
    mockPermissions([])

    await scope.run(async () => {
      const { isLoaded, unhandledCount } = useCtiSidebar()

      await waitForNextTick()

      expect(isLoaded.value).toBe(false)
      expect(unhandledCount.value).toBeUndefined()
      expect(getGraphQLMockCalls(CtiSidebarDocument)).toHaveLength(0)
    })
  })

  it('shares one query and one subscription between its consumers', async () => {
    await scope.run(async () => {
      mockSidebar()

      const first = useCtiSidebar()
      const second = useCtiSidebar()

      await waitForCtiSidebarQueryCalls()
      await waitForNextTick()

      expect(second).toBe(first)
      expect(second.unhandledCount.value).toBe(3)
      expect(getGraphQLMockCalls(CtiSidebarDocument)).toHaveLength(1)
      expect(getGraphQLMockCalls(CtiSidebarUpdatesDocument)).toHaveLength(1)
    })
  })

  it('queries again after a reconnect', async () => {
    await scope.run(async () => {
      mockSidebar()

      useCtiSidebar()

      await waitForCtiSidebarQueryCalls()

      emitter.emit('reconnected')

      await waitUntil(() => getGraphQLMockCalls(CtiSidebarDocument).length === 2)
    })
  })

  it('applies a pushed update without querying again', async () => {
    await scope.run(async () => {
      mockSidebar()

      const { unhandledCount, ringingCalls } = useCtiSidebar()

      await waitForCtiSidebarQueryCalls()
      await waitForNextTick()

      await pushSidebar({ __typename: 'CtiSidebar', unhandledCount: 4, ringingCalls: [] })
      await waitForNextTick()

      expect(unhandledCount.value).toBe(4)
      expect(ringingCalls.value).toEqual([])
      expect(getGraphQLMockCalls(CtiSidebarDocument)).toHaveLength(1)
    })
  })

  it('keeps the loaded state while the subscription carries no payload', async () => {
    await scope.run(async () => {
      mockSidebar()

      const { unhandledCount, ringingCalls } = useCtiSidebar()

      await waitForCtiSidebarQueryCalls()
      await waitForNextTick()

      await pushSidebar(null)
      await waitForNextTick()

      expect(unhandledCount.value).toBe(3)
      expect(ringingCalls.value).toEqual([expect.objectContaining({ id: ringingCall.id })])
    })
  })
})
