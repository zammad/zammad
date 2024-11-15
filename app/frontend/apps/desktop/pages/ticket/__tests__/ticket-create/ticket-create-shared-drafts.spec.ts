// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { waitFor, within } from '@testing-library/vue'

import ticketCustomerObjectAttributes from '#tests/graphql/factories/fixtures/ticket-customer-object-attributes.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { waitForFormUpdaterQueryCalls } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { mockObjectManagerFrontendAttributesQuery } from '#shared/entities/object-attributes/graphql/queries/objectManagerFrontendAttributes.mocks.ts'
import { waitForTicketCreateMutationCalls } from '#shared/entities/ticket/graphql/mutations/create.mocks.ts'
import { waitForTicketSharedDraftStartCreateMutationCalls } from '#shared/entities/ticket-shared-draft-start/graphql/mutations/ticketSharedDraftStartCreate.mocks.ts'
import { waitForTicketSharedDraftStartDeleteMutationCalls } from '#shared/entities/ticket-shared-draft-start/graphql/mutations/ticketSharedDraftStartDelete.mocks.ts'
import { waitForTicketSharedDraftStartUpdateMutationCalls } from '#shared/entities/ticket-shared-draft-start/graphql/mutations/ticketSharedDraftStartUpdate.mocks.ts'
import {
  mockTicketSharedDraftStartListQuery,
  waitForTicketSharedDraftStartListQueryCalls,
} from '#shared/entities/ticket-shared-draft-start/graphql/queries/ticketSharedDraftStartList.mocks.ts'
import {
  mockTicketSharedDraftStartSingleQuery,
  waitForTicketSharedDraftStartSingleQueryCalls,
} from '#shared/entities/ticket-shared-draft-start/graphql/queries/ticketSharedDraftStartSingle.mocks.ts'
import { getTicketSharedDraftStartUpdateByGroupSubscriptionHandler } from '#shared/entities/ticket-shared-draft-start/graphql/subscriptions/ticketSharedDraftStartUpdateByGroup.mocks.ts'
import {
  convertToGraphQLId,
  getIdFromGraphQLId,
} from '#shared/graphql/utils.ts'

import { handleMockFormUpdaterQuery } from '#desktop/pages/ticket/__tests__/support/ticket-create-helpers.ts'

vi.hoisted(() => {
  vi.setSystemTime('2024-07-03T13:48:09Z')
})

describe('ticket create view - shared drafts sidebar', async () => {
  describe('with agent permissions', async () => {
    beforeEach(() => {
      mockApplicationConfig({
        ui_ticket_create_available_types: [
          'phone-in',
          'phone-out',
          'email-out',
        ],
      })
      mockPermissions(['ticket.agent'])
      handleMockFormUpdaterQuery()
    })

    it('supports creating shared drafts', async () => {
      const view = await visitView('/ticket/create')

      await view.events.type(
        await view.findByLabelText('Text'),
        'foobar<div data-signature="true">Signature here</div>',
      )

      const formUpdaterCalls = await waitForFormUpdaterQueryCalls()
      await vi.waitUntil(() => formUpdaterCalls.length === 2)

      mockTicketSharedDraftStartListQuery({
        ticketSharedDraftStartList: [],
      })

      await view.events.click(view.getByLabelText('Group'))
      await view.events.click(view.getByRole('option', { name: 'Users' }))

      await waitForTicketSharedDraftStartListQueryCalls()

      const aside = within(
        view.getByRole('complementary', {
          name: 'Content sidebar',
        }),
      )

      await view.events.type(
        aside.getByLabelText('Create a shared draft'),
        'Test shared draft 1',
      )

      await getNode('sharedDraftTitle')?.settled

      await view.events.click(
        aside.getByRole('link', { name: 'Create Shared Draft' }),
      )

      const calls = await waitForTicketSharedDraftStartCreateMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({
        name: 'Test shared draft 1',
        input: expect.objectContaining({
          groupId: convertToGraphQLId('Group', 1),
          content: expect.objectContaining({
            body: 'foobar',
          }),
        }),
      })

      expect(view.getByRole('alert')).toHaveTextContent(
        'Shared draft has been created successfully.',
      )

      await getTicketSharedDraftStartUpdateByGroupSubscriptionHandler().trigger(
        {
          ticketSharedDraftStartUpdateByGroup: {
            sharedDraftStarts: [
              {
                id: convertToGraphQLId('Ticket::SharedDraftStart', 1),
                name: 'Test shared draft 1',
                updatedAt: '2024-07-03T13:48:09Z',
                updatedBy: {
                  fullname: 'Erika Mustermann',
                },
              },
            ],
          },
        },
      )

      await waitForNextTick()

      expect(
        aside.getByRole('link', { name: 'Test shared draft 1' }),
      ).toBeInTheDocument()
    })

    it('supports applying shared drafts', async () => {
      const view = await visitView('/ticket/create')

      const draftToMock = {
        id: convertToGraphQLId('Ticket::SharedDraftStart', 1),
        name: 'Test shared draft 1',
        content: {
          title: 'foobar',
          customer_id: 'test@example.com',
          body: 'body',
        },
        updatedAt: '2024-07-03T13:48:09Z',
        updatedBy: {
          fullname: 'Erika Mustermann',
        },
      }

      mockTicketSharedDraftStartListQuery({
        ticketSharedDraftStartList: [draftToMock],
      })

      await view.events.click(await view.findByLabelText('Group'))
      await view.events.click(view.getByRole('option', { name: 'Users' }))

      await waitForTicketSharedDraftStartListQueryCalls()

      const aside = within(
        view.getByRole('complementary', {
          name: 'Content sidebar',
        }),
      )

      mockTicketSharedDraftStartSingleQuery({
        ticketSharedDraftStartSingle: draftToMock,
      })

      await view.events.click(
        aside.getByRole('link', { name: draftToMock.name }),
      )

      await waitForTicketSharedDraftStartSingleQueryCalls()

      const flyout = within(
        view.getByRole('complementary', {
          name: 'Preview Shared Draft',
        }),
      )

      expect(
        flyout.getByText(draftToMock.updatedBy.fullname),
      ).toBeInTheDocument()
      expect(flyout.getByText('just now')).toBeInTheDocument()
      expect(flyout.getByText(draftToMock.content.body)).toBeInTheDocument()

      await view.events.click(flyout.getByRole('button', { name: 'Apply' }))

      expect(
        await view.findByRole('dialog', { name: 'Apply Draft' }),
      ).toBeInTheDocument()

      const dialog = within(
        view.getByRole('dialog', {
          name: 'Apply Draft',
        }),
      )

      handleMockFormUpdaterQuery({
        title: { value: draftToMock.content.title },
        customer_id: {
          value: draftToMock.content.customer_id,
          options: [{ value: draftToMock.content.customer_id }],
        },
        body: { value: draftToMock.content.body },
        pending_time: { show: false },
        shared_draft_id: { value: getIdFromGraphQLId(draftToMock.id) },
      })

      await view.events.click(
        dialog.getByRole('button', { name: 'Overwrite Content' }),
      )

      await waitFor(() => {
        expect(
          view.queryByRole('dialog', {
            name: 'Apply Draft',
          }),
        ).not.toBeInTheDocument()
      })

      const formUpdaterCalls = await waitForFormUpdaterQueryCalls()

      expect(formUpdaterCalls.at(-1)?.variables).toEqual(
        expect.objectContaining({
          meta: expect.objectContaining({
            additionalData: expect.objectContaining({
              sharedDraftId: draftToMock.id,
              draftType: 'start',
            }),
          }),
        }),
      )

      await waitForNextTick()

      expect(view.getByLabelText('Title')).toHaveValue(
        draftToMock.content.title,
      )

      await view.events.click(view.getByRole('button', { name: 'Create' }))

      const ticketCreateCalls = await waitForTicketCreateMutationCalls()
      expect(ticketCreateCalls.at(-1)?.variables).toEqual(
        expect.objectContaining({
          input: expect.objectContaining({
            title: draftToMock.content.title,
            sharedDraftId: draftToMock.id,
          }),
        }),
      )
    })

    it('supports updating shared drafts', async () => {
      const view = await visitView('/ticket/create')

      mockTicketSharedDraftStartListQuery({
        ticketSharedDraftStartList: [
          {
            id: convertToGraphQLId('Ticket::SharedDraftStart', 1),
            name: 'Test shared draft 1',
            updatedAt: '2024-07-03T13:48:09Z',
            updatedBy: {
              fullname: 'Erika Mustermann',
            },
          },
        ],
      })

      await view.events.click(await view.findByLabelText('Group'))
      await view.events.click(view.getByRole('option', { name: 'Users' }))

      await waitForTicketSharedDraftStartListQueryCalls()

      const aside = within(
        view.getByRole('complementary', {
          name: 'Content sidebar',
        }),
      )

      mockTicketSharedDraftStartSingleQuery({
        ticketSharedDraftStartSingle: {
          name: 'Test shared draft 1',
          content: {
            body: 'foobar',
          },
          updatedAt: '2024-07-03T13:48:09Z',
          updatedBy: {
            fullname: 'Erika Mustermann',
          },
        },
      })

      await view.events.click(
        aside.getByRole('link', { name: 'Test shared draft 1' }),
      )

      await waitForTicketSharedDraftStartSingleQueryCalls()

      const flyout = within(
        view.getByRole('complementary', {
          name: 'Preview Shared Draft',
        }),
      )

      await view.events.click(flyout.getByRole('button', { name: 'Apply' }))

      const dialog = within(
        await view.findByRole('dialog', { name: 'Apply Draft' }),
      )

      handleMockFormUpdaterQuery({
        shared_draft_id: {
          value: 1,
        },
        body: {
          value: 'foobar',
        },
      })

      await view.events.click(
        dialog.getByRole('button', { name: 'Overwrite Content' }),
      )

      await waitFor(() => {
        expect(
          view.queryByRole('complementary', {
            name: 'Preview Shared Draft',
          }),
        ).not.toBeInTheDocument()
      })

      await view.events.click(
        aside.getByRole('button', { name: 'Update Shared Draft' }),
      )

      const calls = await waitForTicketSharedDraftStartUpdateMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({
        sharedDraftId: convertToGraphQLId('Ticket::SharedDraftStart', 1),
        input: expect.objectContaining({
          content: expect.objectContaining({
            body: 'foobar',
          }),
        }),
      })

      expect(view.getByRole('alert')).toHaveTextContent(
        'Shared draft has been updated successfully.',
      )

      expect(
        aside.getByRole('button', { name: 'Update Shared Draft' }),
      ).toBeInTheDocument()
    })

    it('supports deleting shared drafts', async () => {
      const view = await visitView('/ticket/create')

      mockTicketSharedDraftStartListQuery({
        ticketSharedDraftStartList: [
          {
            id: convertToGraphQLId('Ticket::SharedDraftStart', 1),
            name: 'Test shared draft 1',
            updatedAt: '2024-07-03T13:48:09Z',
            updatedBy: {
              fullname: 'Erika Mustermann',
            },
          },
        ],
      })

      await view.events.click(await view.findByLabelText('Group'))
      await view.events.click(view.getByRole('option', { name: 'Users' }))

      await waitForTicketSharedDraftStartListQueryCalls()

      const aside = within(
        view.getByRole('complementary', {
          name: 'Content sidebar',
        }),
      )

      mockTicketSharedDraftStartSingleQuery({
        ticketSharedDraftStartSingle: {
          name: 'Test shared draft 1',
          content: {
            body: 'foobar',
          },
          updatedAt: '2024-07-03T13:48:09Z',
          updatedBy: {
            fullname: 'Erika Mustermann',
          },
        },
      })

      await view.events.click(
        aside.getByRole('link', { name: 'Test shared draft 1' }),
      )

      await waitForTicketSharedDraftStartSingleQueryCalls()

      const flyout = within(
        view.getByRole('complementary', {
          name: 'Preview Shared Draft',
        }),
      )

      await view.events.click(flyout.getByRole('button', { name: 'Delete' }))

      const dialog = within(
        await view.findByRole('dialog', { name: 'Delete Object' }),
      )

      await view.events.click(
        dialog.getByRole('button', { name: 'Delete Object' }),
      )

      const calls = await waitForTicketSharedDraftStartDeleteMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({
        sharedDraftId: convertToGraphQLId('Ticket::SharedDraftStart', 1),
      })

      await waitFor(() => {
        expect(
          view.queryByRole('complementary', {
            name: 'Preview Shared Draft',
          }),
        ).not.toBeInTheDocument()
      })

      // FIXME: Check why returning an empty array triggers the following console error in test environment only.
      //   Cache data may be lost when replacing the ticketSharedDraftStartList field of a Query object.
      await getTicketSharedDraftStartUpdateByGroupSubscriptionHandler().trigger(
        {
          ticketSharedDraftStartUpdateByGroup: {},
        },
      )

      expect(
        aside.queryByRole('link', { name: 'Test shared draft 1' }),
      ).not.toBeInTheDocument()
    })
  })

  describe('with customer permission', () => {
    beforeEach(() => {
      mockApplicationConfig({
        customer_ticket_create: true,
      })
      mockPermissions(['ticket.customer'])
      // Mock frontend attributes for customer context.
      mockObjectManagerFrontendAttributesQuery({
        objectManagerFrontendAttributes: ticketCustomerObjectAttributes(),
      })
      handleMockFormUpdaterQuery()
    })

    it('does not show', async () => {
      const view = await visitView('/ticket/create')

      await view.events.click(await view.findByLabelText('Group'))
      await view.events.click(view.getByRole('option', { name: 'Users' }))

      await waitForFormUpdaterQueryCalls()

      expect(
        view.queryByRole('complementary', {
          name: 'Content sidebar',
        }),
      ).not.toBeInTheDocument()
    })
  })
})
