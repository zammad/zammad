// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { effectScope, toRef } from 'vue'

import { waitForNextTick } from '#tests/support/utils.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { EnumLinkType } from '#shared/graphql/types.ts'

import { mockLinkListQuery } from '../../graphql/queries/linkList.mocks.ts'
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
              id: 'gid://zammad/Ticket/2',
              title: 'Ticket 2',
            },
            type: EnumLinkType.Child,
          },
          {
            item: {
              __typename: 'Ticket',
              id: 'gid://zammad/Ticket/3',
              title: 'Ticket 3',
            },
            type: EnumLinkType.Child,
          },
          {
            item: {
              __typename: 'Ticket',
              id: 'gid://zammad/Ticket/4',
              title: 'Ticket 4',
            },
            type: EnumLinkType.Normal,
          },
        ],
      })

      const { linkTypesWithLinks } = useObjectLinks(
        toRef(createDummyTicket()),
        'Ticket',
      )

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
                id: 'gid://zammad/Ticket/4',
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
                id: 'gid://zammad/Ticket/2',
                title: 'Ticket 2',
              }),
              type: EnumLinkType.Child,
            },
            {
              __typename: 'Link',
              item: expect.objectContaining({
                id: 'gid://zammad/Ticket/3',
                title: 'Ticket 3',
              }),
              type: EnumLinkType.Child,
            },
          ],
        },
      ])
    })
  })
})
