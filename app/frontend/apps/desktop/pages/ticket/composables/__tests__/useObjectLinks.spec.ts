// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { flushPromises } from '@vue/test-utils'
import { effectScope, ref, toRef } from 'vue'

import { waitForNextTick } from '#tests/support/utils.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { EnumLinkType } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import {
  mockLinkListQuery,
  waitForLinkListQueryCalls,
} from '../../graphql/queries/linkList.mocks.ts'
import { useObjectLinks } from '../useObjectLinks.ts'

const scope = effectScope()

describe('useObjectLinks', () => {
  it('returns types with links', async () => {
    await scope.run(async () => {
      mockLinkListQuery({
        linkList: [
          {
            item: {
              __typename: 'Ticket',
              id: convertToGraphQLId('Ticket', 2),
              title: 'Ticket 2',
            },
            type: EnumLinkType.Child,
          },
          {
            item: {
              __typename: 'Ticket',
              id: convertToGraphQLId('Ticket', 3),
              title: 'Ticket 3',
            },
            type: EnumLinkType.Child,
          },
          {
            item: {
              __typename: 'Ticket',
              id: convertToGraphQLId('Ticket', 4),
              title: 'Ticket 4',
            },
            type: EnumLinkType.Normal,
          },
        ],
      })

      const { linkTypesWithLinks } = useObjectLinks(toRef(createDummyTicket()), 'Ticket')

      await waitForNextTick()

      expect(linkTypesWithLinks.value).toEqual([
        {
          value: 'normal',
          label: 'Normal',
          id: expect.any(String),
          links: [
            {
              __typename: 'Link',
              item: expect.objectContaining({
                id: convertToGraphQLId('Ticket', 4),
                title: 'Ticket 4',
              }),
              type: EnumLinkType.Normal,
            },
          ],
        },
        {
          value: 'child',
          label: 'Child',
          id: expect.any(String),
          links: [
            {
              __typename: 'Link',
              item: expect.objectContaining({
                id: convertToGraphQLId('Ticket', 2),
                title: 'Ticket 2',
              }),
              type: EnumLinkType.Child,
            },
            {
              __typename: 'Link',
              item: expect.objectContaining({
                id: convertToGraphQLId('Ticket', 3),
                title: 'Ticket 3',
              }),
              type: EnumLinkType.Child,
            },
          ],
        },
      ])
    })
  })

  it('exposes the raw, ungrouped links', async () => {
    await scope.run(async () => {
      mockLinkListQuery({
        linkList: [
          {
            item: {
              __typename: 'Ticket',
              id: convertToGraphQLId('Ticket', 2),
              title: 'Ticket 2',
            },
            type: EnumLinkType.Child,
          },
        ],
      })

      const { links } = useObjectLinks(toRef(createDummyTicket()), 'Ticket')

      await waitForNextTick()

      expect(links.value).toEqual([
        {
          __typename: 'Link',
          item: expect.objectContaining({ id: convertToGraphQLId('Ticket', 2), title: 'Ticket 2' }),
          type: EnumLinkType.Child,
        },
      ])
    })
  })

  it('runs the query only once enabled', async () => {
    await scope.run(async () => {
      mockLinkListQuery({
        linkList: [
          {
            item: {
              __typename: 'Ticket',
              id: convertToGraphQLId('Ticket', 2),
              title: 'Ticket 2',
            },
            type: EnumLinkType.Normal,
          },
        ],
      })

      const enabled = ref(false)
      const { links } = useObjectLinks(toRef(createDummyTicket()), 'Ticket', { enabled })

      await flushPromises()
      expect(links.value).toEqual([])

      enabled.value = true
      await waitForLinkListQueryCalls()

      await waitFor(() => expect(links.value).toHaveLength(1))
    })
  })
})
