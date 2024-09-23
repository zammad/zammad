// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'

import { renderComponent } from '#tests/support/components/index.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { pushComponent } from '#shared/components/DynamicInitializer/manage.ts'
import { waitForTicketSharedDraftStartCreateMutationCalls } from '#shared/entities/ticket-shared-draft-start/graphql/mutations/ticketSharedDraftStartCreate.mocks.ts'
import { useTicketSharedDraftStartDeleteMutation } from '#shared/entities/ticket-shared-draft-start/graphql/mutations/ticketSharedDraftStartDelete.api.ts'
import { waitForTicketSharedDraftStartUpdateMutationCalls } from '#shared/entities/ticket-shared-draft-start/graphql/mutations/ticketSharedDraftStartUpdate.mocks.ts'
import { useTicketSharedDraftStartSingleQuery } from '#shared/entities/ticket-shared-draft-start/graphql/queries/ticketSharedDraftStartSingle.api.ts'
import type { TicketSharedDraftStartListQuery } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { TicketSidebarScreenType } from '../../../../types/sidebar.ts'
import sharedDraftStartSidebarPlugin from '../../plugins/shared-draft-start.ts'
import TicketSidebarSharedDraftStartContent from '../TicketSidebarSharedDraftStartContent.vue'

vi.hoisted(() => {
  vi.setSystemTime(new Date('2024-07-03T13:48:09Z'))
})

vi.mock('#shared/components/DynamicInitializer/manage.ts', () => {
  return {
    destroyComponent: vi.fn(),
    pushComponent: vi.fn(),
  }
})

const renderTicketSidebarSharedDraftStartContent = async (
  sharedDraftStartList: TicketSharedDraftStartListQuery['ticketSharedDraftStartList'],
  context: {
    formValues: Record<string, unknown>
    form?: Record<string, unknown>
  },
  options: any = {},
) => {
  const result = renderComponent(TicketSidebarSharedDraftStartContent, {
    props: {
      sidebarPlugin: sharedDraftStartSidebarPlugin,
      sharedDraftStartList,
      context: {
        screenType: TicketSidebarScreenType.TicketCreate,
        ...context,
      },
    },
    router: true,
    form: true,
    ...options,
  })

  await waitForNextTick()

  return result
}

describe('TicketSidebarSharedDraftStartContent.vue', () => {
  it('renders empty shared draft list', async () => {
    const wrapper = await renderTicketSidebarSharedDraftStartContent([], {
      formValues: {
        group_id: 2,
      },
    })

    expect(wrapper.getByRole('heading')).toHaveTextContent('Shared Drafts')
    expect(wrapper.getByLabelText('Create a shared draft')).toBeInTheDocument()

    expect(
      wrapper.getByRole('link', { name: 'Create Shared Draft' }),
    ).toBeInTheDocument()

    expect(wrapper.getByText('No shared drafts yet')).toBeInTheDocument()
  })

  it('renders non-empty shared draft list', async () => {
    const wrapper = await renderTicketSidebarSharedDraftStartContent(
      [
        {
          id: convertToGraphQLId('Ticket::SharedDraftStart', 1),
          name: 'Test shared draft 1',
          updatedAt: '2024-07-03T13:48:09Z',
          updatedBy: {
            __typename: 'User',
            id: convertToGraphQLId('User', 2),
            internalId: 2,
            firstname: 'Erika',
            lastname: 'Mustermann',
            fullname: 'Erika Mustermann',
          },
        },
        {
          id: convertToGraphQLId('Ticket::SharedDraftStart', 2),
          name: 'Test shared draft 2',
          updatedAt: '2024-07-03T13:30:00Z',
          updatedBy: {
            __typename: 'User',
            id: convertToGraphQLId('User', 3),
            internalId: 3,
            firstname: 'Max',
            lastname: 'Mustermann',
            fullname: 'Max Mustermann',
          },
        },
        {
          id: convertToGraphQLId('Ticket::SharedDraftStart', 3),
          name: 'Test shared draft 3',
          updatedAt: '2024-07-02T12:00:00Z',
        },
      ],
      {
        formValues: {
          group_id: 2,
        },
      },
    )

    expect(
      wrapper.getByRole('link', { name: 'Test shared draft 1' }),
    ).toBeInTheDocument()

    expect(wrapper.getByText('just now')).toBeInTheDocument()
    expect(wrapper.getByText('• Erika Mustermann')).toBeInTheDocument()

    expect(
      wrapper.getByRole('link', { name: 'Test shared draft 2' }),
    ).toBeInTheDocument()

    expect(wrapper.getByText('18 minutes ago')).toBeInTheDocument()
    expect(wrapper.getByText('• Max Mustermann')).toBeInTheDocument()

    expect(
      wrapper.getByRole('link', { name: 'Test shared draft 3' }),
    ).toBeInTheDocument()

    expect(wrapper.getByText('1 day ago')).toBeInTheDocument()
  })

  it('supports previewing shared draft', async () => {
    const wrapper = await renderTicketSidebarSharedDraftStartContent(
      [
        {
          id: convertToGraphQLId('Ticket::SharedDraftStart', 1),
          name: 'Test shared draft 1',
          updatedAt: '2024-07-03T13:48:09Z',
          updatedBy: {
            __typename: 'User',
            id: convertToGraphQLId('User', 2),
            internalId: 2,
            firstname: 'Erika',
            lastname: 'Mustermann',
            fullname: 'Erika Mustermann',
          },
        },
      ],
      {
        formValues: {
          group_id: 2,
        },
        form: {
          formId: 'test-form',
        },
      },
    )

    await wrapper.events.click(
      wrapper.getByRole('link', { name: 'Test shared draft 1' }),
    )

    expect(pushComponent).toHaveBeenCalledWith(
      'flyout',
      'shared-draft',
      expect.anything(),
      {
        form: {
          formId: 'test-form',
        },
        sharedDraftId: convertToGraphQLId('Ticket::SharedDraftStart', 1),
        draftType: 'start',
        metaInformationQuery: useTicketSharedDraftStartSingleQuery,
        deleteMutation: useTicketSharedDraftStartDeleteMutation,
      },
    )
  })

  it('supports creating new shared draft', async () => {
    const wrapper = await renderTicketSidebarSharedDraftStartContent([], {
      formValues: {
        group_id: 2,
        title: 'Test Title',
        articleSenderType: 'email-out',
        cc: ['foo@example.org', 'bar@example.org'],
        tags: ['tag 1', 'tag 2', 'tag 3'],
      },
      form: {
        formId: 'test-form',
      },
    })

    await wrapper.events.type(
      wrapper.getByLabelText('Create a shared draft'),
      'foobar',
    )

    await getNode('sharedDraftTitle')?.settled

    await wrapper.events.click(
      wrapper.getByRole('link', { name: 'Create Shared Draft' }),
    )

    const calls = await waitForTicketSharedDraftStartCreateMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      name: 'foobar',
      input: {
        groupId: convertToGraphQLId('Group', 2),
        formId: 'test-form',
        content: {
          formSenderType: 'email-out',
          title: 'Test Title',
          cc: 'foo@example.org, bar@example.org',
          tags: 'tag 1, tag 2, tag 3',
        },
      },
    })
  })

  it('supports updating existing shared draft', async () => {
    const wrapper = await renderTicketSidebarSharedDraftStartContent(
      [
        {
          id: convertToGraphQLId('Ticket::SharedDraftStart', 1),
          name: 'Test shared draft 1',
          updatedAt: '2024-07-03T13:48:09Z',
          updatedBy: {
            __typename: 'User',
            id: convertToGraphQLId('User', 2),
            internalId: 2,
            firstname: 'Erika',
            lastname: 'Mustermann',
            fullname: 'Erika Mustermann',
          },
        },
      ],
      {
        formValues: {
          group_id: 2,
          shared_draft_id: 1,
          title: 'Test Title',
          articleSenderType: 'email-out',
          cc: ['foo@example.org', 'bar@example.org'],
          tags: ['tag 1', 'tag 2', 'tag 3'],
        },
        form: {
          formId: 'test-form',
        },
      },
    )

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'Update Shared Draft' }),
    )

    const calls = await waitForTicketSharedDraftStartUpdateMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      sharedDraftId: convertToGraphQLId('Ticket::SharedDraftStart', 1),
      input: {
        groupId: convertToGraphQLId('Group', 2),
        formId: 'test-form',
        content: {
          formSenderType: 'email-out',
          title: 'Test Title',
          cc: 'foo@example.org, bar@example.org',
          tags: 'tag 1, tag 2, tag 3',
        },
      },
    })
  })
})
