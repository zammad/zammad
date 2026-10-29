// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { EnumTicketArticleSenderName } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import {
  mockTicketInfoForPopoverQuery,
  waitForTicketInfoForPopoverQueryCalls,
} from '../TicketPopoverWithTrigger/graphql/queries/ticketInfoForPopover.mocks.ts'
import TicketPopoverWithTrigger, { type Props } from '../TicketPopoverWithTrigger.vue'

const popoverArticle = (
  id: number,
  excerpt: string,
  senderName: EnumTicketArticleSenderName,
  internal = false,
) => ({
  __typename: 'TicketArticle' as const,
  id: convertToGraphQLId('Ticket::Article', id),
  createdAt: '2026-10-20T12:00:00Z',
  bodyExcerpt: excerpt,
  internal,
  author: {
    __typename: 'User' as const,
    id: convertToGraphQLId('User', senderName === EnumTicketArticleSenderName.Agent ? 3 : 2),
    fullname: senderName === EnumTicketArticleSenderName.Agent ? 'Agent 1 Test' : 'Nicole Braun',
    firstname: senderName === EnumTicketArticleSenderName.Agent ? 'Agent 1' : 'Nicole',
    lastname: senderName === EnumTicketArticleSenderName.Agent ? 'Test' : 'Braun',
    image: null,
  },
  // Without an id the factory rolls a random one, and the mocker stores objects by id: two
  //   senders could end up as one, with a single name for both articles.
  sender: {
    __typename: 'TicketArticleSender' as const,
    id: convertToGraphQLId(
      'TicketArticleSender',
      senderName === EnumTicketArticleSenderName.Agent ? 1 : 2,
    ),
    name: senderName,
  },
})

const firstArticle = popoverArticle(
  1,
  'I can no longer log in via SSO.',
  EnumTicketArticleSenderName.Customer,
)
const lastArticle = popoverArticle(
  2,
  'I have reset the SSO link for your account.',
  EnumTicketArticleSenderName.Agent,
)

const storedSummary = {
  __typename: 'TicketAIAssistanceSummary' as const,
  customerRequest: 'Customer wants a corrected invoice.',
  customerMood: 'annoyed',
  customerEmotion: '😠',
}

const dummyTicket = {
  ...createDummyTicket({
    owner: {
      id: convertToGraphQLId('User', 3),
      internalId: 3,
      fullname: 'Agent 1 Test',
    },
  }),
  aiStoredSummary: storedSummary,
  firstArticle,
  lastArticle,
  checklist: null,
}

interface TicketOverride {
  aiStoredSummary?: typeof storedSummary | null
  firstArticle?: typeof firstArticle | null
  lastArticle?: typeof lastArticle | null
  checklist?: {
    __typename: 'Checklist'
    id: string
    complete: number
    total: number
    completed: boolean
  } | null
}

const renderTicketPopover = (props?: Partial<Props>, ticketOverride?: TicketOverride) => {
  mockTicketInfoForPopoverQuery({
    ticket: { ...dummyTicket, ...ticketOverride },
  })

  return renderComponent(TicketPopoverWithTrigger, {
    props: {
      ticket: {
        id: dummyTicket.id,
        number: dummyTicket.number,
        internalId: dummyTicket.internalId,
        state: dummyTicket.state,
        stateColorCode: dummyTicket.stateColorCode,
        title: dummyTicket.title,
      },
      ...props,
    },
    router: true,
  })
}

describe('TicketPopoverWithTrigger', () => {
  beforeEach(() => {
    mockPermissions(['ticket.agent'])

    mockApplicationConfig({
      ticket_hook: 'Ticket#',
      ai_assistance_ticket_summary_config: {
        open_questions: false,
        upcoming_events: false,
        customer_sentiment: true,
        generate_on: 'on_ticket_detail_opening',
      },
    })
  })

  it('displays a label by default', () => {
    const wrapper = renderTicketPopover()

    expect(wrapper.getByRole('link', { name: dummyTicket.title })).toBeVisible()
  })

  it('displays a ticket popover', async () => {
    const wrapper = renderTicketPopover()

    await wrapper.events.hover(wrapper.getByRole('link'))

    const calls = await waitForTicketInfoForPopoverQueryCalls()

    expect(calls.at(-1)?.variables).toEqual({
      ticketId: dummyTicket.id,
      withContent: false,
    })

    const popover = await wrapper.findByRole('region')

    expect(within(popover).getByText(dummyTicket.title)).toBeVisible()
    expect(within(popover).getByRole('status', { name: 'open' })).toHaveAttribute(
      'aria-roledescription',
      '(ticket status: open)',
    )

    expect(within(popover).getByRole('heading', { name: 'Owner' })).toBeVisible()
    expect(within(popover).getByRole('link', { name: dummyTicket.owner.fullname! })).toBeVisible()

    expect(within(popover).getByRole('heading', { name: 'Customer' })).toBeVisible()
    expect(
      within(popover).getByRole('link', { name: dummyTicket.customer.fullname! }),
    ).toBeVisible()

    expect(within(popover).getByRole('heading', { name: 'Organization' })).toBeVisible()
    expect(
      within(popover).getByRole('link', { name: dummyTicket.organization!.name! }),
    ).toBeVisible()

    expect(within(popover).getByText('Ticket#')).toBeVisible()
    expect(within(popover).getByText(dummyTicket.number)).toBeVisible()

    expect(within(popover).getByText('Created at')).toBeVisible()
    expect(within(popover).getByTestId('date-time-relative')).toBeVisible()

    expect(within(popover).getByText('Group')).toBeVisible()
    expect(within(popover).getByText(dummyTicket.group.name!)).toBeVisible()

    expect(within(popover).getByText('Priority')).toBeVisible()
    expect(within(popover).getByText(dummyTicket.priority.name)).toBeVisible()

    expect(within(popover).queryByText('Customer intent')).not.toBeInTheDocument()
    expect(within(popover).queryByText('Latest article')).not.toBeInTheDocument()
  })

  describe('with details', () => {
    it('shows the intent, the sentiment and the last article with a summary', async () => {
      const wrapper = renderTicketPopover({ withContent: true })

      await wrapper.events.hover(wrapper.getByRole('link'))

      const calls = await waitForTicketInfoForPopoverQueryCalls()

      expect(calls.at(-1)?.variables).toEqual({
        ticketId: dummyTicket.id,
        withContent: true,
      })

      const popover = await wrapper.findByRole('region')

      expect(await within(popover).findByText('Customer intent')).toBeVisible()
      expect(within(popover).getByText('Customer wants a corrected invoice.')).toBeVisible()
      expect(within(popover).getByText('Customer sentiment')).toBeVisible()
      expect(within(popover).getByText('😠')).toBeVisible()
      expect(within(popover).getByText('annoyed')).toBeVisible()
      expect(
        within(popover).getByText('Be sure to check AI-generated content for accuracy.'),
      ).toBeVisible()

      expect(within(popover).getByText(`Ticket#${dummyTicket.number}`)).toBeVisible()
      expect(within(popover).getByRole('button', { name: 'Copy ticket number' })).toBeVisible()

      expect(within(popover).getByText('Latest article')).toBeVisible()
      expect(within(popover).getByText('I have reset the SSO link for your account.')).toBeVisible()
      expect(within(popover).getByText('Agent 1 Test')).toBeVisible()

      expect(within(popover).queryByText('First article')).not.toBeInTheDocument()
      expect(within(popover).queryByText('Priority')).not.toBeInTheDocument()
      expect(within(popover).queryByRole('heading', { name: 'Owner' })).not.toBeInTheDocument()
    })

    it('hides the sentiment when it is not enabled', async () => {
      mockApplicationConfig({
        ticket_hook: 'Ticket#',
        ai_assistance_ticket_summary_config: {
          open_questions: false,
          upcoming_events: false,
          customer_sentiment: false,
          generate_on: 'on_ticket_detail_opening',
        },
      })

      const wrapper = renderTicketPopover({ withContent: true })

      await wrapper.events.hover(wrapper.getByRole('link'))

      const popover = await wrapper.findByRole('region')

      expect(await within(popover).findByText('Customer intent')).toBeVisible()
      expect(within(popover).queryByText('Customer sentiment')).not.toBeInTheDocument()
      expect(within(popover).queryByText('annoyed')).not.toBeInTheDocument()
    })

    it('falls back to the first and the last article without a summary', async () => {
      const wrapper = renderTicketPopover({ withContent: true }, { aiStoredSummary: null })

      await wrapper.events.hover(wrapper.getByRole('link'))

      const popover = await wrapper.findByRole('region')

      expect(await within(popover).findByText('First article')).toBeVisible()
      expect(within(popover).getByText('I can no longer log in via SSO.')).toBeVisible()
      expect(within(popover).getByText('Nicole Braun')).toBeVisible()

      expect(within(popover).getByText('Latest article')).toBeVisible()
      expect(within(popover).getByText('I have reset the SSO link for your account.')).toBeVisible()

      expect(within(popover).queryByText('Customer intent')).not.toBeInTheDocument()
    })

    it('puts the customer article on the side opposite to the agent article', async () => {
      const wrapper = renderTicketPopover({ withContent: true }, { aiStoredSummary: null })

      await wrapper.events.hover(wrapper.getByRole('link'))

      const popover = await wrapper.findByRole('region')

      const bubbleOf = (authorName: string) =>
        within(popover).getByText(authorName).closest('[data-test-id="popover-article-bubble"]')

      await within(popover).findByText('Nicole Braun')

      await vi.waitFor(() => {
        expect(bubbleOf('Nicole Braun')).toHaveClass('flex-row-reverse')
        expect(bubbleOf('Agent 1 Test')).not.toHaveClass('flex-row-reverse')
      })
    })

    it('marks an internal article as an internal note', async () => {
      const internalArticle = popoverArticle(
        3,
        'Only for the team.',
        EnumTicketArticleSenderName.Agent,
        true,
      )

      const wrapper = renderTicketPopover(
        { withContent: true },
        { aiStoredSummary: null, firstArticle: internalArticle, lastArticle: internalArticle },
      )

      await wrapper.events.hover(wrapper.getByRole('link'))

      const popover = await wrapper.findByRole('region')

      const bubble = await within(popover).findByTestId('popover-article-bubble')

      expect(bubble.lastElementChild).toHaveClass('bg-stripes')
    })

    it('shows a single article as the latest article', async () => {
      const wrapper = renderTicketPopover(
        { withContent: true },
        { aiStoredSummary: null, firstArticle, lastArticle: firstArticle },
      )

      await wrapper.events.hover(wrapper.getByRole('link'))

      const popover = await wrapper.findByRole('region')

      expect(await within(popover).findByText('Latest article')).toBeVisible()
      expect(within(popover).getByText('I can no longer log in via SSO.')).toBeVisible()

      expect(within(popover).queryByText('First article')).not.toBeInTheDocument()
    })

    it('links the summary sidebar from the sentiment badge', async () => {
      const wrapper = renderTicketPopover({ withContent: true })

      await wrapper.events.hover(wrapper.getByRole('link', { name: dummyTicket.title }))

      const popover = await wrapper.findByRole('region')

      const badge = (await within(popover).findByText('Customer sentiment')).closest('a')

      // The emoji sits between the label and the mood, as in the design.
      expect(badge).toHaveTextContent('Customer sentiment😠annoyed')
      expect(badge).toHaveAttribute(
        'href',
        `/desktop/tickets/${dummyTicket.internalId}?sidebar=ticket-summary`,
      )
    })

    it('links the open checklist', async () => {
      mockApplicationConfig({
        ticket_hook: 'Ticket#',
        checklist: true,
        ai_assistance_ticket_summary_config: {
          open_questions: false,
          upcoming_events: false,
          customer_sentiment: true,
          generate_on: 'on_ticket_detail_opening',
        },
      })

      const wrapper = renderTicketPopover(
        { withContent: true },
        {
          checklist: {
            __typename: 'Checklist',
            id: convertToGraphQLId('Checklist', 1),
            complete: 1,
            total: 3,
            completed: false,
          },
        },
      )

      await wrapper.events.hover(wrapper.getByRole('link', { name: dummyTicket.title }))

      const popover = await wrapper.findByRole('region')

      const badge = (await within(popover).findByText('Checked')).closest('a')

      expect(badge).toHaveTextContent('Checked')
      expect(badge).toHaveTextContent('1 of 3')
      expect(badge).toHaveAttribute(
        'href',
        `/desktop/tickets/${dummyTicket.internalId}?sidebar=checklist`,
      )
    })

    it('hides a completed checklist', async () => {
      mockApplicationConfig({
        ticket_hook: 'Ticket#',
        checklist: true,
        ai_assistance_ticket_summary_config: {
          open_questions: false,
          upcoming_events: false,
          customer_sentiment: true,
          generate_on: 'on_ticket_detail_opening',
        },
      })

      const wrapper = renderTicketPopover(
        { withContent: true },
        {
          checklist: {
            __typename: 'Checklist',
            id: convertToGraphQLId('Checklist', 1),
            complete: 3,
            total: 3,
            completed: true,
          },
        },
      )

      await wrapper.events.hover(wrapper.getByRole('link', { name: dummyTicket.title }))

      const popover = await wrapper.findByRole('region')

      expect(await within(popover).findByText('Customer intent')).toBeVisible()
      expect(within(popover).queryByText('Checked')).not.toBeInTheDocument()
    })

    it('shows no article section when only system notifications exist', async () => {
      const wrapper = renderTicketPopover(
        { withContent: true },
        { aiStoredSummary: null, firstArticle: null, lastArticle: null },
      )

      await wrapper.events.hover(wrapper.getByRole('link'))

      const popover = await wrapper.findByRole('region')

      expect(await within(popover).findByText(dummyTicket.title)).toBeVisible()
      expect(within(popover).queryByText('Latest article')).not.toBeInTheDocument()
      expect(within(popover).queryByText('First article')).not.toBeInTheDocument()
    })
  })
})
