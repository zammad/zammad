// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { waitFor, within } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { waitForTicketCreateMutationCalls } from '#shared/entities/ticket/graphql/mutations/create.mocks.ts'
import {
  EnumTaskbarEntity,
  EnumTaskbarEntityAccess,
  EnumTicketExternalReferencesIssueTrackerItemState,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import getUuid from '#shared/utils/getUuid.ts'

import { mockUserCurrentTaskbarItemListQuery } from '#desktop/entities/user/current/graphql/queries/userCurrentTaskbarItemList.mocks.ts'
import {
  handleCustomerMock,
  handleMockFormUpdaterQuery,
  handleMockUserQuery,
} from '#desktop/pages/ticket/__tests__/support/ticket-create-helpers.ts'

import { mockTicketExternalReferencesIssueTrackerItemAddMutation } from '../../graphql/mutations/ticketExternalReferencesIssueTrackerItemAdd.mocks.ts'
import { mockTicketExternalReferencesIssueTrackerItemListQuery } from '../../graphql/queries/ticketExternalReferencesIssueTrackerList.mocks.ts'

describe('Ticket create GitHub links', () => {
  it('displays sidebar', async () => {
    mockPermissions(['ticket.agent'])

    await mockApplicationConfig({
      github_integration: true,
    })

    const uid = getUuid()

    mockUserCurrentTaskbarItemListQuery({
      userCurrentTaskbarItemList: [
        {
          __typename: 'UserTaskbarItem',
          id: convertToGraphQLId('Taskbar', 1),
          key: `TicketCreateScreen-${uid}`,
          callback: EnumTaskbarEntity.TicketCreate,
          entityAccess: EnumTaskbarEntityAccess.Granted,
          entity: null,
        },
      ],
    })

    const view = await visitView(`/ticket/create/${uid}`)

    const sidebar = view.getByLabelText('Content sidebar')

    expect(
      within(sidebar).getByRole('button', { name: 'GitHub' }),
    ).toBeInTheDocument()
  })

  it('hides sidebar when not available', async () => {
    mockPermissions(['ticket.agent'])

    await mockApplicationConfig({
      github_integration: false,
    })

    const uid = getUuid()

    mockUserCurrentTaskbarItemListQuery({
      userCurrentTaskbarItemList: [
        {
          __typename: 'UserTaskbarItem',
          id: convertToGraphQLId('Taskbar', 2),
          key: `TicketCreateScreen-${uid}`,
          callback: EnumTaskbarEntity.TicketCreate,
          entityAccess: EnumTaskbarEntityAccess.Granted,
          entity: null,
        },
      ],
    })

    const view = await visitView(`/ticket/create/${uid}`)

    const sidebar = view.getByLabelText('Content sidebar')

    expect(
      within(sidebar).queryByRole('button', { name: 'GitHub' }),
    ).not.toBeInTheDocument()
  })

  it('submits a new ticket with github links', async () => {
    mockApplicationConfig({
      github_integration: true,
      ui_task_mananger_max_task_count: 30,
      ui_ticket_create_available_types: ['phone-in', 'phone-out', 'email-out'],
    })

    handleMockFormUpdaterQuery({
      pending_time: {
        show: false,
      },
    })

    mockTicketExternalReferencesIssueTrackerItemListQuery({
      ticketExternalReferencesIssueTrackerItemList: [],
    })

    const uid = getUuid()

    mockUserCurrentTaskbarItemListQuery({
      userCurrentTaskbarItemList: [
        {
          __typename: 'UserTaskbarItem',
          id: convertToGraphQLId('Taskbar', 3),
          key: `TicketCreateScreen-${uid}`,
          callback: EnumTaskbarEntity.TicketCreate,
          entityAccess: EnumTaskbarEntityAccess.Granted,
          entity: null,
        },
      ],
    })

    const view = await visitView(`/ticket/create/${uid}`)

    await view.events.click(view.getByRole('button', { name: 'GitHub' }))

    await waitFor(() =>
      expect(
        view.getByRole('heading', { level: 1, name: 'New Ticket' }),
      ).toBeInTheDocument(),
    )

    await view.events.type(view.getByLabelText('Title'), 'Test Ticket')

    await handleCustomerMock(view)

    handleMockUserQuery()

    await view.events.click(
      view.getByRole('option', {
        name: 'Avatar (Nicole Braun) Nicole Braun – Zammad Foundation',
      }),
    )

    await view.events.click(view.getByLabelText('Text'))
    await view.events.type(view.getByLabelText('Text'), 'Test ticket text')

    await view.events.click(view.getByLabelText('Group'))
    await view.events.click(view.getByRole('option', { name: 'Users' }))

    await view.events.click(view.getByLabelText('Priority'))
    await view.events.click(view.getByRole('option', { name: '2 normal' }))

    await view.events.click(view.getByLabelText('State'))
    await view.events.click(view.getByRole('option', { name: 'open' }))

    const sidebar = view.getByLabelText('Content sidebar')

    await view.events.click(
      await within(sidebar).findByRole('button', {
        name: 'Link Issue',
      }),
    )

    const flyout = await view.findByRole('complementary', {
      name: 'GitHub: Link issue',
    })

    await view.events.type(
      within(flyout).getByLabelText('Issue URL'),
      'https://github.com/zammad/zammad/issues/123',
    )

    mockTicketExternalReferencesIssueTrackerItemAddMutation({
      ticketExternalReferencesIssueTrackerItemAdd: {
        issueTrackerItem: {
          issueId: 123,
          url: 'https://github.com/zammad/zammad/issues/123',
          title: 'Issue 1',
          state: EnumTicketExternalReferencesIssueTrackerItemState.Open,
        },
        errors: null,
      },
    })

    await view.events.click(
      within(flyout).getByRole('button', { name: 'Link Issue' }),
    )

    expect(await within(sidebar).findByText('#123 Issue 1')).toBeInTheDocument()

    await view.events.click(view.getByRole('button', { name: 'Create' }))

    const calls = await waitForTicketCreateMutationCalls()
    expect(calls.at(-1)?.variables.input).toEqual(
      expect.objectContaining({
        externalReferences: {
          github: ['https://github.com/zammad/zammad/issues/123'],
        },
      }),
    )
  })
})
