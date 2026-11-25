// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { waitFor, within } from '@testing-library/vue'

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { getClipboardItemData } from '#tests/support/mocks/clipboardItem.ts'

import { mockFormUpdaterQuery } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { TicketUpdateDocument } from '#shared/entities/ticket/graphql/mutations/update.api.ts'
import {
  mockTicketUpdateMutation,
  waitForTicketUpdateMutationCalls,
} from '#shared/entities/ticket/graphql/mutations/update.mocks.ts'
import { mockTicketArticlesQuery } from '#shared/entities/ticket/graphql/queries/ticket/articles.mocks.ts'
import { mockTicketQuery } from '#shared/entities/ticket/graphql/queries/ticket.mocks.ts'
import { createDummyArticle } from '#shared/entities/ticket-article/__tests__/mocks/ticket-articles.ts'
import {
  createDummyTicket,
  defaultGroup,
} from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { EnumTicketArticleSenderName } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import * as domUtils from '#shared/utils/dom.ts'

import { mockLinkListQuery } from '#desktop/entities/link/graphql/queries/linkList.mocks.ts'

const copyToClipboard = vi.fn()

vi.mock('#shared/composables/useCopyToClipboard.ts', async () => {
  const mod = await vi.importActual<typeof import('#shared/composables/useCopyToClipboard.ts')>(
    '#shared/composables/useCopyToClipboard.ts',
  )

  return { ...mod, useCopyToClipboard: () => ({ copyToClipboard }) }
})

// The mocked schema keeps one record per ID, so each article type needs its own.
const withType = (article: ReturnType<typeof createDummyArticle>, id: number, name: string) => ({
  ...article,
  type: {
    __typename: 'TicketArticleType' as const,
    id: convertToGraphQLId('TicketArticleType', id),
    name,
    communication: name === 'email',
  },
})

const emailArticle = withType(
  createDummyArticle({
    articleId: 1,
    senderName: EnumTicketArticleSenderName.Customer,
    to: {
      raw: '',
      parsed: [
        { emailAddress: 'first@example.com', isSystemAddress: false },
        { emailAddress: 'second@example.com', isSystemAddress: false },
      ],
    },
  }),
  1,
  'email',
)

const noteArticle = withType(createDummyArticle({ articleId: 2, internal: true }), 10, 'note')

const stateOptions = (defaultClose: number | null) =>
  (
    [
      [4, 'closed'],
      [2, 'open'],
      [6, 'pending close'],
    ] as const
  ).map(([value, label]) => ({ value, label, defaultClose: value === defaultClose }))

const visitTicket = async ({
  update = true,
  agentReadAccess = true,
  defaultClose = 4 as number | null,
  articles = [emailArticle, noteArticle],
  readOnlyState = false,
} = {}) => {
  mockTicketQuery({
    ticket: createDummyTicket({
      number: '31001',
      title: 'Printer on fire',
      group: {
        ...defaultGroup,
        __typename: 'Group',
        emailAddress: {
          __typename: 'EmailAddressParsed',
          name: 'Zammad',
          emailAddress: 'zammad@example.com',
        },
      },
      defaultPolicy: { update, agentReadAccess },
    }),
  })

  mockTicketArticlesQuery({
    articles: { totalCount: articles.length, edges: articles.map((node) => ({ node })) },
    firstArticles: { edges: [{ node: articles[0] }] },
  })

  mockFormUpdaterQuery({
    formUpdater: {
      fields: {
        group_id: { options: [{ value: 2, label: 'Test Agents' }] },
        owner_id: { options: [{ value: 3, label: 'Test Admin Agent' }] },
        state_id: { options: stateOptions(defaultClose), disabled: readOnlyState },
        pending_time: { show: false },
        priority_id: { options: [{ value: 2, label: '2 normal' }] },
      },
      flags: { newArticlePresent: false },
    },
  })

  const view = await visitView('/tickets/1')

  await getNode('form-ticket-edit-1')?.settled
  await view.findAllByRole('heading', { level: 2, name: 'Printer on fire' })
  await view.findAllByRole('article')

  return view
}

const formField = (name: string) => getNode('form-ticket-edit-1')?.find(name, 'name')

const settleForm = () => getNode('form-ticket-edit-1')?.settled

const ticketUpdates = () => getGraphQLMockCalls(TicketUpdateDocument)

describe('Ticket detail view - keyboard shortcuts', () => {
  beforeEach(() => {
    mockPermissions(['ticket.agent'])
    mockApplicationConfig({
      ui_ticket_zoom_article_note_new_internal: true,
      ticket_hook: 'Ticket#',
      http_type: 'https',
      fqdn: 'zammad.example.com',
    })
    mockLinkListQuery({ linkList: [] })
    copyToClipboard.mockClear()

    // The press count is global, like the old view's: forget the presses of earlier examples.
    window.dispatchEvent(new KeyboardEvent('keyup', { key: 'Escape' }))
  })

  describe('x and i', () => {
    it('opens an internal note and toggles its visibility, which a second x keeps', async () => {
      const view = await visitTicket()

      await view.events.keyboard('x')

      const replyPanel = within(await view.findByRole('complementary', { name: 'Reply' }))

      await waitFor(() => expect(replyPanel.getByRole('textbox')).toHaveFocus())
      expect(formField('internal')?.value).toBe(true)

      replyPanel.getByRole('textbox').blur()
      await view.events.keyboard('i')

      await waitFor(() => expect(formField('internal')?.value).toBe(false))

      await view.events.keyboard('x')

      await waitFor(() => expect(replyPanel.getByRole('textbox')).toHaveFocus())
      expect(formField('internal')?.value).toBe(false)
    })
  })

  describe('r', () => {
    it('replies to all on the last article offering a reply', async () => {
      const view = await visitTicket()

      await view.events.keyboard('r')

      const replyPanel = within(await view.findByRole('complementary', { name: 'Reply' }))

      expect(await replyPanel.findByText('second@example.com')).toBeInTheDocument()
      expect(replyPanel.getByText('first@example.com')).toBeInTheDocument()
      expect(formField('answeredArticleId')?.value).toBe(emailArticle.id)
    })

    it('forgets the answered article when a note is opened afterwards', async () => {
      const view = await visitTicket()

      await view.events.keyboard('r')
      await waitFor(() => expect(formField('answeredArticleId')?.value).toBe(emailArticle.id))

      const replyPanel = within(await view.findByRole('complementary', { name: 'Reply' }))
      replyPanel.getByRole('textbox').blur()

      await view.events.keyboard('x')

      await waitFor(() => expect(formField('answeredArticleId')?.value).toBeNull())
    })

    it('does nothing without an article offering a reply', async () => {
      const view = await visitTicket({ articles: [noteArticle] })

      await view.events.keyboard('r')

      expect(view.queryByRole('complementary', { name: 'Reply' })).not.toBeInTheDocument()
    })
  })

  describe('shift+c', () => {
    it('updates the ticket with the default close state', async () => {
      const view = await visitTicket()

      mockFormUpdaterQuery({ formUpdater: { fields: {}, flags: {} } })

      await view.events.keyboard('{Shift>}C{/Shift}')

      const calls = await waitForTicketUpdateMutationCalls()

      expect(calls.at(-1)?.variables.input).toEqual(
        expect.objectContaining({ stateId: convertToGraphQLId('Ticket::State', 4) }),
      )
    })

    it('fills in a pending time when the default close state asks for one', async () => {
      const view = await visitTicket({ defaultClose: 6 })

      mockFormUpdaterQuery({
        formUpdater: { fields: { pending_time: { show: true, required: true } }, flags: {} },
      })

      await view.events.keyboard('{Shift>}C{/Shift}')

      const calls = await waitForTicketUpdateMutationCalls()
      const { input } = calls.at(-1)!.variables

      const expectedDay = new Date()
      expectedDay.setDate(expectedDay.getDate() + 3)

      expect(input.stateId).toBe(convertToGraphQLId('Ticket::State', 6))
      expect(new Date(input.pendingTime).toDateString()).toBe(expectedDay.toDateString())
    })

    it('does nothing while no state is the default close state', async () => {
      const view = await visitTicket({ defaultClose: null })

      await view.events.keyboard('{Shift>}C{/Shift}')
      await settleForm()

      expect(formField('state_id')?.value).toBe(2)
      expect(ticketUpdates()).toHaveLength(0)
    })

    it('does nothing when the update still running takes the close state off the offer', async () => {
      const view = await visitTicket()

      const result = {
        formUpdater: {
          fields: {
            state_id: { options: stateOptions(null).filter(({ value }) => value !== 4) },
          },
          flags: {},
        },
      }

      let finishFormUpdate = () => {}
      let isFirstUpdate = true

      mockFormUpdaterQuery(() => {
        if (!isFirstUpdate) return result

        isFirstUpdate = false

        return new Promise((resolve) => {
          finishFormUpdate = () => resolve(result)
        })
      })

      formField('state_id')?.input(6)
      await waitFor(() =>
        expect(getNode('form-ticket-edit-1')?.context?.state.formUpdaterProcessing).toBe(true),
      )

      await view.events.keyboard('{Shift>}C{/Shift}')
      finishFormUpdate()
      await settleForm()

      // A press still waiting for a state it may not set would go on with the next update, and
      //   submit a few tasks later.
      formField('state_id')?.input(2)
      await settleForm()
      await new Promise((resolve) => setTimeout(resolve, 100))

      expect(formField('state_id')?.value).toBe(2)
      expect(ticketUpdates()).toHaveLength(0)
    })

    it('does not change a state a core workflow made read-only', async () => {
      const view = await visitTicket({ readOnlyState: true })

      await view.events.keyboard('{Shift>}C{/Shift}')
      await settleForm()

      expect(formField('state_id')?.value).toBe(2)
      expect(ticketUpdates()).toHaveLength(0)
    })

    it('does not start again while waiting for the state change to apply', async () => {
      const view = await visitTicket()

      let finishFormUpdate = () => {}

      mockFormUpdaterQuery((variables) => {
        const result = { formUpdater: { fields: {}, flags: {} } }

        if (variables.meta.changedField?.name !== 'state_id') return result

        return new Promise((resolve) => {
          finishFormUpdate = () => resolve(result)
        })
      })

      await view.events.keyboard('{Shift>}C{/Shift}')
      await waitFor(() => expect(formField('state_id')?.value).toBe(4))

      await view.events.keyboard('{Shift>}C{/Shift}')

      mockTicketUpdateMutation(() => new Promise(() => {}))
      finishFormUpdate()

      await waitForTicketUpdateMutationCalls()

      // The form submits a request made while its updater ran in a later task.
      await new Promise((resolve) => setTimeout(resolve))
      await settleForm()

      expect(ticketUpdates()).toHaveLength(1)
    })

    it('does not submit again while the update is under way', async () => {
      const view = await visitTicket()

      mockFormUpdaterQuery({ formUpdater: { fields: {}, flags: {} } })

      let finishUpdate = () => {}

      mockTicketUpdateMutation(
        () =>
          new Promise((resolve) => {
            finishUpdate = () => resolve({ ticketUpdate: { ticket: null, errors: null } })
          }),
      )

      await view.events.keyboard('{Shift>}C{/Shift}')
      await waitForTicketUpdateMutationCalls()

      await view.events.keyboard('{Shift>}C{/Shift}')
      await settleForm()

      expect(ticketUpdates()).toHaveLength(1)

      finishUpdate()
    })
  })

  describe('ctrl+enter', () => {
    it('updates the ticket from the reply editor', async () => {
      const view = await visitTicket()

      await view.events.keyboard('x')

      const editor = await view.findByRole('textbox', { name: 'Text' })
      await view.events.type(editor, 'Foo note')
      await settleForm()

      await view.events.keyboard('{Control>}{Enter}{/Control}')

      const calls = await waitForTicketUpdateMutationCalls()

      expect(calls.at(-1)?.variables.input).toEqual(
        expect.objectContaining({ article: expect.objectContaining({ body: 'Foo note' }) }),
      )
    })

    it('does nothing while the focus is outside the ticket form', async () => {
      const view = await visitTicket()

      await view.events.keyboard('x')
      await view.events.type(await view.findByRole('textbox', { name: 'Text' }), 'Foo note')
      await settleForm()

      view.getAllByRole('button', { name: 'Copy ticket number' })[0].focus()
      await view.events.keyboard('{Control>}{Enter}{/Control}')
      await settleForm()

      expect(ticketUpdates()).toHaveLength(0)
    })
  })

  describe('.', () => {
    it('copies the number, then with the title, then with the link', async () => {
      const view = await visitTicket()

      await view.events.keyboard('...')

      expect(copyToClipboard).toHaveBeenNthCalledWith(1, 'Ticket#31001')
      expect(copyToClipboard).toHaveBeenNthCalledWith(2, 'Ticket#31001: Printer on fire')

      const [item] = copyToClipboard.mock.calls[2][0]
      const url = 'https://zammad.example.com/desktop/tickets/1'

      expect(getClipboardItemData(item)['text/plain']).toBe(`Ticket#31001: Printer on fire\n${url}`)
      expect(getClipboardItemData(item)['text/html']).toBe(
        `<a href="${url}">Ticket#31001</a>: Printer on fire`,
      )
    })
  })

  describe('on a ticket the user cannot update', () => {
    it('changes nothing, but copies the number', async () => {
      const view = await visitTicket({ update: false })

      await view.events.keyboard('xr{Shift>}C{/Shift}.')
      await settleForm()

      expect(formField('articleType')?.value).toBeFalsy()
      expect(formField('state_id')?.value).toBe(2)
      expect(ticketUpdates()).toHaveLength(0)
      expect(copyToClipboard).toHaveBeenCalledWith('Ticket#31001')
    })
  })

  describe('for customers', () => {
    it('does not open a note', async () => {
      mockPermissions(['ticket.customer'])

      const view = await visitTicket({ agentReadAccess: false })

      await view.events.keyboard('x')

      expect(view.queryByRole('complementary', { name: 'Reply' })).not.toBeInTheDocument()
    })

    it('keeps the reply of an agent who is the customer of the ticket public', async () => {
      mockPermissions(['ticket.agent', 'ticket.customer'])

      const view = await visitTicket({ agentReadAccess: false })

      await view.events.click(await view.findByRole('button', { name: 'Add reply' }))

      const replyPanel = within(await view.findByRole('complementary', { name: 'Reply' }))

      await waitFor(() => expect(replyPanel.getByRole('textbox')).toHaveFocus())
      expect(formField('internal')?.value).toBe(false)

      replyPanel.getByRole('textbox').blur()
      await view.events.keyboard('i')
      await settleForm()

      expect(formField('internal')?.value).toBe(false)
    })
  })

  describe('arrow keys', () => {
    it('navigate the articles only while nothing has the focus', async () => {
      const view = await visitTicket()

      const scrollIntoView = vi.spyOn(domUtils, 'scrollIntoView')
      scrollIntoView.mockClear()

      const noteButton = view.getAllByRole('button', { name: 'Add internal note' })[0]

      noteButton.focus()
      await view.events.keyboard('{ArrowRight}')

      expect(scrollIntoView).not.toHaveBeenCalled()

      noteButton.blur()
      await view.events.keyboard('{Shift>}{ArrowRight}{/Shift}')

      expect(scrollIntoView).not.toHaveBeenCalled()

      // Every article is at the top in this environment, so there is none to go to next.
      await view.events.keyboard('{ArrowRight}')

      expect(scrollIntoView).toHaveBeenCalledWith(expect.anything(), 'end', expect.anything())
    })
  })
})
