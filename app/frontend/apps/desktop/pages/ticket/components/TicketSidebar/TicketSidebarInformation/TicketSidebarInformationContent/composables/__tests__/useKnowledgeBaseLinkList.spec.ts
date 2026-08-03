// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { flushPromises } from '@vue/test-utils'
import { effectScope, ref } from 'vue'

import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { EnumLinkType } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import {
  mockLinkListQuery,
  waitForLinkListQueryCalls,
} from '#desktop/pages/ticket/graphql/queries/linkList.mocks.ts'
import { getLinkUpdatesSubscriptionHandler } from '#desktop/pages/ticket/graphql/subscriptions/linkUpdates.mocks.ts'

import { useKnowledgeBaseLinkList } from '../useKnowledgeBaseLinkList.ts'

const ticketId = convertToGraphQLId('Ticket', 1)

const answerId = (id: number) => convertToGraphQLId('KnowledgeBase::Answer::Translation', id)

const linkedAnswer = (id: number, title: string) => ({
  item: {
    __typename: 'KnowledgeBaseAnswerTranslation' as const,
    id: answerId(id),
    title,
  },
  type: EnumLinkType.Normal,
})

describe('useKnowledgeBaseLinkList', () => {
  it('exposes the linked answers, their ids and the target type', async () => {
    const scope = effectScope()

    await scope.run(async () => {
      mockLinkListQuery({
        linkList: [linkedAnswer(1, 'Reset your password'), linkedAnswer(2, 'Set up 2FA')],
      })

      const { linkedAnswers, linkedAnswerIds, targetType } = useKnowledgeBaseLinkList(
        ref(ticketId),
        { enabled: ref(true) },
      )

      await waitForLinkListQueryCalls()
      await waitFor(() => expect(linkedAnswers.value).toHaveLength(2))

      expect(linkedAnswers.value).toEqual([
        expect.objectContaining({ id: answerId(1), title: 'Reset your password' }),
        expect.objectContaining({ id: answerId(2), title: 'Set up 2FA' }),
      ])
      expect(linkedAnswerIds.value).toEqual([answerId(1), answerId(2)])
      expect(targetType).toBe('KnowledgeBase::Answer::Translation')
    })

    scope.stop()
  })

  it('applies link updates from the subscription without a refetch', async () => {
    const scope = effectScope()

    await scope.run(async () => {
      mockLinkListQuery({ linkList: [linkedAnswer(1, 'Reset your password')] })

      const { linkedAnswers, linkedAnswerIds } = useKnowledgeBaseLinkList(ref(ticketId), {
        enabled: ref(true),
      })

      await waitForLinkListQueryCalls()
      await waitFor(() => expect(linkedAnswers.value).toHaveLength(1))

      await getLinkUpdatesSubscriptionHandler().trigger({
        linkUpdates: {
          links: [linkedAnswer(1, 'Reset your password'), linkedAnswer(3, 'Enable notifications')],
        },
      })

      await waitFor(() => expect(linkedAnswers.value).toHaveLength(2))
      expect(linkedAnswerIds.value).toEqual([answerId(1), answerId(3)])

      await getLinkUpdatesSubscriptionHandler().trigger({
        linkUpdates: {
          links: [],
        },
      })

      await waitFor(() => expect(linkedAnswers.value).toEqual([]))
    })

    scope.stop()
  })

  it('runs the query only once enabled', async () => {
    const scope = effectScope()

    await scope.run(async () => {
      mockLinkListQuery({ linkList: [linkedAnswer(1, 'Reset your password')] })

      const enabled = ref(false)
      const { linkedAnswers } = useKnowledgeBaseLinkList(ref(ticketId), { enabled })

      await flushPromises()
      expect(linkedAnswers.value).toEqual([])

      enabled.value = true
      await waitForLinkListQueryCalls()

      await waitFor(() => expect(linkedAnswers.value).toHaveLength(1))
    })

    scope.stop()
  })
})
