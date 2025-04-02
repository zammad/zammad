// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import {
  getByLabelText,
  getByRole,
  waitFor,
  within,
} from '@testing-library/vue'
import { expect } from 'vitest'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import {
  mockAutocompleteSearchRecipientQuery,
  waitForAutocompleteSearchRecipientQueryCalls,
} from '#shared/components/Form/fields/FieldRecipient/graphql/queries/autocompleteSearch/recipient.mocks.ts'
import { mockFormUpdaterQuery } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { waitForTicketUpdateMutationCalls } from '#shared/entities/ticket/graphql/mutations/update.mocks.ts'
import { mockTicketArticlesQuery } from '#shared/entities/ticket/graphql/queries/ticket/articles.mocks.ts'
import { mockTicketQuery } from '#shared/entities/ticket/graphql/queries/ticket.mocks.ts'
import { getTicketUpdatesSubscriptionHandler } from '#shared/entities/ticket/graphql/subscriptions/ticketUpdates.mocks.ts'
import { createDummyArticle } from '#shared/entities/ticket-article/__tests__/mocks/ticket-articles.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mockLinkListQuery } from '../../graphql/queries/linkList.mocks.ts'

describe('Ticket detail view', () => {
  beforeEach(() => {
    mockPermissions(['ticket.agent'])

    mockLinkListQuery({
      linkList: [],
    })
  })

  describe('Ticket attributes', () => {
    it('updates ticket state to closed', async () => {
      const ticket = createDummyTicket({
        state: {
          id: convertToGraphQLId('Ticket::State', 2),
          name: 'open',
          stateType: {
            id: convertToGraphQLId('TicketStateType', 2),
            name: 'open',
          },
        },
        defaultPolicy: {
          update: true,
          agentReadAccess: true,
        },
      })

      mockTicketQuery({
        ticket,
      })

      mockFormUpdaterQuery({
        formUpdater: {
          fields: {
            group_id: {
              options: [
                {
                  value: 1,
                  label: 'Users',
                },
                {
                  value: 2,
                  label: 'test group',
                },
              ],
            },
            owner_id: {
              options: [
                {
                  value: 3,
                  label: 'Test Admin Agent',
                },
              ],
            },
            state_id: {
              options: [
                {
                  value: 4,
                  label: 'closed',
                },
                {
                  value: 2,
                  label: 'open',
                },
                {
                  value: 6,
                  label: 'pending close',
                },
                {
                  value: 3,
                  label: 'pending reminder',
                },
              ],
            },
            pending_time: {
              show: false,
            },
            priority_id: {
              options: [
                {
                  value: 1,
                  label: '1 low',
                },
                {
                  value: 2,
                  label: '2 normal',
                },
                {
                  value: 3,
                  label: '3 high',
                },
              ],
            },
          },
          flags: {
            newArticlePresent: false,
          },
        },
      })

      const view = await visitView('/tickets/1')

      await getNode('form-ticket-edit')?.settled

      expect(
        view.findByRole('heading', {
          level: 2,
          name: 'Ticket',
        }),
      )

      const statusBadges = view.getAllByTestId('common-badge')

      const hasOpenTicketStatus = statusBadges.some((badge) =>
        within(badge).getByText('open'),
      )

      expect(hasOpenTicketStatus).toBe(true)

      const ticketMetaSidebar = within(view.getByLabelText('Content sidebar'))

      await view.events.click(await ticketMetaSidebar.findByLabelText('State'))

      expect(
        await view.findByRole('listbox', { name: 'Select…' }),
      ).toBeInTheDocument()

      mockFormUpdaterQuery({
        formUpdater: {
          fields: {
            state_id: { value: 4 },
          },
        },
      })

      await view.events.click(view.getByRole('option', { name: 'closed' }))

      await getNode('form-ticket-edit')?.settled

      await view.events.click(view.getByRole('button', { name: 'Update' }))

      const calls = await waitForTicketUpdateMutationCalls()

      expect(calls?.at(-1)?.variables).toEqual({
        input: {
          article: null,
          groupId: convertToGraphQLId('Group', 2),
          objectAttributeValues: [],
          ownerId: convertToGraphQLId('User', 1),
          priorityId: convertToGraphQLId('Ticket::Priority', 2),
          stateId: convertToGraphQLId('Ticket::State', 4), // Updates from open to closed 2 -> 4
        },
        meta: {
          skipValidators: [],
          macroId: undefined,
        },
        ticketId: convertToGraphQLId('Ticket', 1),
      })

      await getTicketUpdatesSubscriptionHandler().trigger({
        ticketUpdates: {
          ticket: {
            ...ticket,
            state: {
              ...ticket.state,
              id: convertToGraphQLId('Ticket::State', 4),
              name: 'closed',
              stateType: {
                ...ticket.state.stateType,
                id: convertToGraphQLId('Ticket::StateType', 5),
                name: 'closed',
              },
            },
          },
        },
      })

      await waitForNextTick()

      const hasClosedTicketStatus = statusBadges.some((badge) =>
        within(badge).getByText('closed'),
      )
      expect(hasClosedTicketStatus).toBe(true)
    })
  })

  describe('Article actions', () => {
    it('adds an internal note', async () => {
      mockApplicationConfig({
        ui_ticket_zoom_article_note_new_internal: true,
      })

      mockTicketQuery({
        ticket: createDummyTicket({
          articleType: 'phone',
          defaultPolicy: {
            update: true,
            agentReadAccess: true,
          },
        }),
      })

      mockTicketArticlesQuery({
        articles: {
          totalCount: 1,
          edges: [
            {
              node: createDummyArticle({
                articleType: 'phone',
                internal: false,
              }),
            },
          ],
        },
      })

      mockFormUpdaterQuery({
        formUpdater: {
          fields: {
            group_id: {
              options: [
                {
                  value: 1,
                  label: 'Users',
                },
                {
                  value: 2,
                  label: 'test group',
                },
              ],
            },
            owner_id: {
              options: [
                {
                  value: 3,
                  label: 'Test Admin Agent',
                },
              ],
            },
            state_id: {
              options: [
                {
                  value: 4,
                  label: 'closed',
                },
                {
                  value: 2,
                  label: 'open',
                },
                {
                  value: 6,
                  label: 'pending close',
                },
                {
                  value: 3,
                  label: 'pending reminder',
                },
              ],
            },
            pending_time: {
              show: false,
            },
            priority_id: {
              options: [
                {
                  value: 1,
                  label: '1 low',
                },
                {
                  value: 2,
                  label: '2 normal',
                },
                {
                  value: 3,
                  label: '3 high',
                },
              ],
            },
          },
          flags: {
            newArticlePresent: false,
          },
        },
      })

      const view = await visitView('/tickets/1')

      await view.events.click(
        await view.findByRole('button', { name: 'Add internal note' }),
      )

      const complementary = await view.findByRole('complementary', {
        name: 'Reply',
      })

      expect(
        getByRole(complementary, 'heading', { level: 2, name: 'Reply' }),
      ).toBeInTheDocument()

      await getNode('form-ticket-edit')?.settled

      expect(getByLabelText(complementary, 'Visibility')).toHaveTextContent(
        'Internal',
      )

      expect(view.getByTestId('article-reply-stripes-panel')).toHaveClass(
        'bg-stripes',
      )

      const editor = view.getByRole('textbox', { name: 'Text' })

      // FIXME: This is not possible to test ATM, due to TipTap editor not being supported in JSDOM.
      // expect(editor).toHaveFocus()

      await view.events.type(editor, 'Foo note')

      await getNode('form-ticket-edit')?.settled

      await view.events.click(view.getByRole('button', { name: 'Update' }))

      const calls = await waitForTicketUpdateMutationCalls()

      expect(calls?.at(-1)?.variables).toEqual(
        expect.objectContaining({
          input: expect.objectContaining({
            article: expect.objectContaining({ body: 'Foo note' }),
          }),
        }),
      )
    })

    it('replies to an article', async () => {
      mockTicketQuery({
        ticket: createDummyTicket({
          group: {
            id: convertToGraphQLId('Group', 1),
            emailAddress: {
              name: 'Zammad Helpdesk',
              emailAddress: 'zammad@localhost',
            },
          },
          articleType: 'email',
          defaultPolicy: {
            update: true,
            agentReadAccess: true,
          },
        }),
      })

      mockTicketArticlesQuery({
        articles: {
          totalCount: 1,
          edges: [
            {
              node: createDummyArticle({
                articleType: 'email',
                internal: false,
              }),
            },
          ],
        },
      })

      mockFormUpdaterQuery({
        formUpdater: {
          fields: {
            group_id: {
              options: [
                {
                  value: 1,
                  label: 'Users',
                },
                {
                  value: 2,
                  label: 'test group',
                },
              ],
            },
            owner_id: {
              options: [
                {
                  value: 3,
                  label: 'Test Admin Agent',
                },
              ],
            },
            state_id: {
              options: [
                {
                  value: 4,
                  label: 'closed',
                },
                {
                  value: 2,
                  label: 'open',
                },
                {
                  value: 6,
                  label: 'pending close',
                },
                {
                  value: 3,
                  label: 'pending reminder',
                },
              ],
            },
            pending_time: {
              show: false,
            },
            priority_id: {
              options: [
                {
                  value: 1,
                  label: '1 low',
                },
                {
                  value: 2,
                  label: '2 normal',
                },
                {
                  value: 3,
                  label: '3 high',
                },
              ],
            },
          },
          flags: {
            newArticlePresent: false,
          },
        },
      })

      const view = await visitView('/tickets/1')

      const articles = await view.findAllByRole('article')

      await view.events.click(
        await within(articles[0]).findByRole('button', { name: 'Reply' }),
      )

      await view.events.type(
        view.getByRole('textbox', { name: 'Text' }),
        'Foo email',
      )

      await getNode('form-ticket-edit')?.settled

      await view.events.click(view.getByRole('button', { name: 'Update' }))

      const calls = await waitForTicketUpdateMutationCalls()

      expect(calls?.at(-1)?.variables).toEqual(
        expect.objectContaining({
          input: expect.objectContaining({
            article: expect.objectContaining({ body: 'Foo email' }),
          }),
        }),
      )
    })

    it('forwards to an article', async () => {
      mockTicketQuery({
        ticket: createDummyTicket({
          group: {
            id: convertToGraphQLId('Group', 1),
            emailAddress: {
              name: 'Zammad Helpdesk',
              emailAddress: 'zammad@localhost',
            },
          },
          articleType: 'email',
          defaultPolicy: {
            update: true,
            agentReadAccess: true,
          },
        }),
      })

      mockTicketArticlesQuery({
        articles: {
          totalCount: 1,
          edges: [
            {
              node: createDummyArticle({
                articleType: 'email',
                internal: false,
              }),
            },
          ],
        },
      })

      mockFormUpdaterQuery({
        formUpdater: {
          fields: {
            group_id: {
              options: [
                {
                  value: 1,
                  label: 'Users',
                },
                {
                  value: 2,
                  label: 'test group',
                },
              ],
            },
            owner_id: {
              options: [
                {
                  value: 3,
                  label: 'Test Admin Agent',
                },
              ],
            },
            state_id: {
              options: [
                {
                  value: 4,
                  label: 'closed',
                },
                {
                  value: 2,
                  label: 'open',
                },
                {
                  value: 6,
                  label: 'pending close',
                },
                {
                  value: 3,
                  label: 'pending reminder',
                },
              ],
            },
            pending_time: {
              show: false,
            },
            priority_id: {
              options: [
                {
                  value: 1,
                  label: '1 low',
                },
                {
                  value: 2,
                  label: '2 normal',
                },
                {
                  value: 3,
                  label: '3 high',
                },
              ],
            },
          },
          flags: {
            newArticlePresent: false,
          },
        },
      })

      const view = await visitView('/tickets/1')

      const articles = await view.findAllByRole('article')

      await view.events.click(
        await within(articles[0]).findByRole('button', {
          name: 'Action menu button',
        }),
      )

      await view.events.click(
        await view.findByRole('button', {
          name: 'Forward',
        }),
      )

      const to = view.getByLabelText('To')

      await view.events.click(to)

      mockAutocompleteSearchRecipientQuery({
        autocompleteSearchRecipient: [],
      })

      await view.events.type(
        within(to).getByRole('searchbox'),
        'nicole.braun@zammad.org',
      )

      await waitForAutocompleteSearchRecipientQueryCalls()

      await view.events.click(
        view.getByRole('button', { name: 'add new email address' }),
      )

      await getNode('form-ticket-edit')?.settled

      await view.events.click(view.getByRole('button', { name: 'Update' }))

      const calls = await waitForTicketUpdateMutationCalls()

      expect(calls?.at(-1)?.variables).toEqual(
        expect.objectContaining({
          input: expect.objectContaining({
            article: expect.objectContaining({
              body: expect.stringContaining('---Begin forwarded message:---'),
            }),
          }),
        }),
      )
    })

    it('discards unsaved changes', async () => {
      mockApplicationConfig({
        ui_ticket_zoom_article_note_new_internal: true,
      })

      mockTicketQuery({
        ticket: createDummyTicket({
          articleType: 'phone',
          defaultPolicy: {
            update: true,
            agentReadAccess: true,
          },
        }),
      })

      const view = await visitView('/tickets/1')

      await view.events.click(
        view.getByRole('button', { name: 'Add phone call' }),
      )

      expect(
        await view.findByRole('heading', { level: 2, name: 'Reply' }),
      ).toBeInTheDocument()

      await view.events.type(
        view.getByRole('textbox', { name: 'Text' }),
        'Foo note',
      )

      await view.events.click(
        view.getByRole('button', { name: 'Discard your unsaved changes' }),
      )

      const confirmDialog = await view.findByRole('dialog')

      expect(confirmDialog).toBeInTheDocument()

      await view.events.click(
        within(confirmDialog).getByRole('button', { name: 'Discard Changes' }),
      )

      await waitFor(() =>
        expect(
          view.queryByRole('textbox', { name: 'Text' }),
        ).not.toBeInTheDocument(),
      )
    })

    it('discards reply form and it keeps the ticket attribute fields state', async () => {
      mockTicketQuery({
        ticket: createDummyTicket({
          articleType: 'phone',
          defaultPolicy: {
            update: true,
            agentReadAccess: true,
          },
        }),
      })

      mockTicketArticlesQuery({
        articles: {
          totalCount: 1,
          edges: [
            {
              node: createDummyArticle({
                articleType: 'phone',
                internal: false,
              }),
            },
          ],
        },
      })

      mockFormUpdaterQuery({
        formUpdater: {
          fields: {
            group_id: {
              options: [
                {
                  value: 1,
                  label: 'Users',
                },
                {
                  value: 2,
                  label: 'test group',
                },
              ],
            },
            owner_id: {
              options: [
                {
                  value: 3,
                  label: 'Test Admin Agent',
                },
              ],
            },
            state_id: {
              options: [
                {
                  value: 4,
                  label: 'closed',
                },
                {
                  value: 2,
                  label: 'open',
                },
                {
                  value: 6,
                  label: 'pending close',
                },
                {
                  value: 3,
                  label: 'pending reminder',
                },
              ],
            },
            pending_time: {
              show: false,
            },
            priority_id: {
              options: [
                {
                  value: 1,
                  label: '1 low',
                },
                {
                  value: 2,
                  label: '2 normal',
                },
                {
                  value: 3,
                  label: '3 high',
                },
              ],
            },
          },
          flags: {
            newArticlePresent: false,
          },
        },
      })

      const view = await visitView('/tickets/1')

      // Discard changes inside the reply form
      await view.events.click(
        view.getByRole('button', { name: 'Add phone call' }),
      )

      expect(
        await view.findByRole('heading', { level: 2, name: 'Reply' }),
      ).toBeInTheDocument()

      // Sets dirty set for a ticket attribute
      await view.events.click(view.getByLabelText('State'))
      await view.events.click(
        await view.findByRole('option', { name: 'closed' }),
      )

      await view.events.click(
        view.getByRole('button', { name: 'Discard unsaved reply' }),
      )

      expect(
        await view.findByRole('dialog', { name: 'Unsaved Changes' }),
      ).toBeInTheDocument()

      await view.events.click(
        view.getByRole('button', { name: 'Discard Changes' }),
      )

      // Verify that ticket attributes state is not lost
      expect(view.getByLabelText('State')).toHaveTextContent('closed')
    })

    it('discards complete form with an reply and afterwards only the reply directly', async () => {
      const ticket = createDummyTicket({
        group: {
          id: convertToGraphQLId('Group', 1),
          emailAddress: {
            name: 'Zammad Helpdesk',
            emailAddress: 'zammad@localhost',
          },
        },
        defaultPolicy: {
          update: true,
          agentReadAccess: true,
        },
      })

      mockTicketQuery({
        ticket,
      })

      mockTicketArticlesQuery({
        articles: {
          totalCount: 1,
          edges: [
            {
              node: createDummyArticle({
                articleType: 'phone',
                internal: false,
              }),
            },
          ],
        },
      })

      mockFormUpdaterQuery({
        formUpdater: {
          fields: {
            group_id: {
              options: [
                {
                  value: 1,
                  label: 'Users',
                },
                {
                  value: 2,
                  label: 'test group',
                },
              ],
            },
            owner_id: {
              options: [
                {
                  value: 3,
                  label: 'Test Admin Agent',
                },
              ],
            },
            state_id: {
              options: [
                {
                  value: 4,
                  label: 'closed',
                },
                {
                  value: 2,
                  label: 'open',
                },
                {
                  value: 6,
                  label: 'pending close',
                },
                {
                  value: 3,
                  label: 'pending reminder',
                },
              ],
            },
            pending_time: {
              show: false,
            },
            priority_id: {
              options: [
                {
                  value: 1,
                  label: '1 low',
                },
                {
                  value: 2,
                  label: '2 normal',
                },
                {
                  value: 3,
                  label: '3 high',
                },
              ],
            },
          },
          flags: {
            newArticlePresent: false,
          },
        },
      })

      const view = await visitView('/tickets/1')

      const ticketMetaSidebar = within(view.getByLabelText('Content sidebar'))
      expect(
        await ticketMetaSidebar.findByLabelText('State'),
      ).toBeInTheDocument()

      await getTicketUpdatesSubscriptionHandler().trigger({
        ticketUpdates: {
          ticket: {
            ...ticket,
            state: {
              ...ticket.state,
              id: convertToGraphQLId('Ticket::State', 4),
              name: 'closed',
              stateType: {
                ...ticket.state.stateType,
                id: convertToGraphQLId('Ticket::StateType', 5),
                name: 'closed',
              },
            },
          },
        },
      })

      await waitForNextTick()

      // Discard changes inside the reply form
      await view.events.click(view.getByRole('button', { name: 'Add reply' }))

      await waitFor(() =>
        expect(
          view.queryByRole('textbox', { name: 'Text' }),
        ).toBeInTheDocument(),
      )

      await view.events.click(
        await view.findByRole('button', {
          name: 'Discard your unsaved changes',
        }),
      )

      expect(
        await view.findByRole('dialog', { name: 'Unsaved Changes' }),
      ).toBeInTheDocument()

      await view.events.click(
        view.getByRole('button', { name: 'Discard Changes' }),
      )

      await waitFor(() => {
        expect(
          view.queryByRole('button', {
            name: 'Discard your unsaved changes',
          }),
        ).not.toBeInTheDocument()
      })

      await view.events.click(view.getByRole('button', { name: 'Add reply' }))

      await view.events.click(
        view.getByRole('button', { name: 'Discard unsaved reply' }),
      )

      const dialog = await view.findByRole('dialog', {
        name: 'Unsaved Changes',
      })

      await view.events.click(
        within(dialog).getByRole('button', { name: 'Discard Changes' }),
      )

      await waitFor(() => {
        expect(
          view.queryByRole('button', {
            name: 'Discard your unsaved changes',
          }),
        ).not.toBeInTheDocument()
      })
    })

    it('shows alert for missing attachments', async () => {
      mockTicketQuery({
        ticket: createDummyTicket({
          group: {
            id: convertToGraphQLId('Group', 1),
            emailAddress: {
              name: 'Zammad Helpdesk',
              emailAddress: 'zammad@localhost',
            },
          },
          articleType: 'email',
          defaultPolicy: {
            update: true,
            agentReadAccess: true,
          },
        }),
      })

      mockTicketArticlesQuery({
        articles: {
          totalCount: 1,
          edges: [
            {
              node: createDummyArticle({
                articleType: 'email',
                internal: false,
              }),
            },
          ],
        },
      })

      mockFormUpdaterQuery({
        formUpdater: {
          fields: {
            group_id: {
              options: [
                {
                  value: 1,
                  label: 'Users',
                },
                {
                  value: 2,
                  label: 'test group',
                },
              ],
            },
            owner_id: {
              options: [
                {
                  value: 3,
                  label: 'Test Admin Agent',
                },
              ],
            },
            state_id: {
              options: [
                {
                  value: 4,
                  label: 'closed',
                },
                {
                  value: 2,
                  label: 'open',
                },
                {
                  value: 6,
                  label: 'pending close',
                },
                {
                  value: 3,
                  label: 'pending reminder',
                },
              ],
            },
            pending_time: {
              show: false,
            },
            priority_id: {
              options: [
                {
                  value: 1,
                  label: '1 low',
                },
                {
                  value: 2,
                  label: '2 normal',
                },
                {
                  value: 3,
                  label: '3 high',
                },
              ],
            },
          },
          flags: {
            newArticlePresent: false,
          },
        },
      })

      const view = await visitView('/tickets/1')

      const articles = await view.findAllByRole('article')

      await view.events.click(
        await within(articles[0]).findByRole('button', { name: 'Reply' }),
      )

      await view.events.type(
        view.getByRole('textbox', { name: 'Text' }),
        'Reply. Check attachment.',
      )

      await getNode('form-ticket-edit')?.settled

      await view.events.click(view.getByRole('button', { name: 'Update' }))

      const dialog = await view.findByRole('dialog', {
        name: 'Confirmation',
      })
      expect(dialog).toBeInTheDocument()

      const dialogView = within(dialog)
      expect(
        dialogView.getByText(
          'Did you plan to include attachments with this message?',
        ),
      ).toBeInTheDocument()
    })
  })

  it('should reset form after ticket updates', async () => {
    const ticket = createDummyTicket({
      state: {
        id: convertToGraphQLId('Ticket::State', 3),
        name: 'open',
        stateType: {
          id: convertToGraphQLId('TicketStateType', 2),
          name: 'open',
        },
      },
      defaultPolicy: {
        update: true,
        agentReadAccess: true,
      },
    })

    mockTicketQuery({
      ticket,
    })

    mockFormUpdaterQuery({
      formUpdater: {
        fields: {
          group_id: {
            options: [
              {
                value: 1,
                label: 'Users',
              },
              {
                value: 2,
                label: 'test group',
              },
            ],
          },
          owner_id: {
            options: [
              {
                value: 3,
                label: 'Test Admin Agent',
              },
            ],
          },
          state_id: {
            options: [
              {
                value: 4,
                label: 'closed',
              },
              {
                value: 2,
                label: 'open',
              },
            ],
          },
          pending_time: {
            show: false,
          },
          priority_id: {
            options: [
              {
                value: 2,
                label: '2 normal',
              },
              {
                value: 2,
                label: '2 normal',
              },
            ],
          },
        },
        flags: {
          newArticlePresent: false,
        },
      },
    })

    const view = await visitView('/tickets/1')

    const ticketMetaSidebar = within(view.getByLabelText('Content sidebar'))

    expect(await view.findByLabelText('Group')).toHaveTextContent('test group')

    await view.events.click(await ticketMetaSidebar.findByLabelText('State'))

    expect(
      await view.findByRole('listbox', { name: 'Select…' }),
    ).toBeInTheDocument()

    await view.events.click(view.getByRole('option', { name: 'closed' }))

    await getTicketUpdatesSubscriptionHandler().trigger({
      ticketUpdates: {
        ticket: {
          ...ticket,
          group: {
            __typename: 'Group',
            id: convertToGraphQLId('Group', 1),
            name: 'Users',
            emailAddress: null,
          },
        },
      },
    })

    const attributesContainer = view.getByTestId('ticket-attributes')

    await waitFor(() =>
      expect(
        within(attributesContainer).getByLabelText('Group'),
      ).toHaveTextContent('Users'),
    )
  })
})
