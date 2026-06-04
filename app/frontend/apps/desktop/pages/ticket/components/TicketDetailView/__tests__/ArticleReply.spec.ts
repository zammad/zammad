// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import ArticleReply from '../ArticleReply.vue'

const defaultTicketArticleTypes = [
  {
    value: 'note',
    label: 'Note',
    buttonLabel: 'Add internal note',
    icon: 'note',
    fields: { attachments: {}, body: { required: true } },
    view: { agent: ['change'] },
    internal: true,
  },
  {
    value: 'phone',
    label: 'Phone',
    buttonLabel: 'Add phone call',
    icon: 'phone',
    fields: { attachments: {}, body: { required: true } },
    view: { agent: ['change'] },
    internal: false,
  },
  {
    value: 'email',
    label: 'Email',
    buttonLabel: 'Add email',
    icon: 'mail',
    view: { agent: ['change'] },
    fields: {
      to: { required: true },
      cc: {},
      body: { required: true },
      subtype: {},
      attachments: {},
      security: {},
    },
    internal: false,
    onDeselected: vi.fn(),
    onOpened: vi.fn(),
    onSelected: vi.fn(),
    performReply: vi.fn(),
  },
]

const renderArticleReply = (props: Record<string, unknown> = {}) =>
  renderComponent(ArticleReply, {
    props: {
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
      ticketArticleTypes: defaultTicketArticleTypes,
      parentReachedBottomScroll: false,
      ...props,
    },
  })

describe('ArticleReply', () => {
  afterEach(() => {
    localStorage.clear()
  })

  it('shows add note button and hint text for agents', () => {
    const wrapper = renderArticleReply()

    expect(wrapper.getByRole('button', { name: 'Add internal note' })).toBeInTheDocument()

    expect(wrapper.getByText('or use the reply actions on articles.')).toBeInTheDocument()

    expect(wrapper.queryByRole('button', { name: 'Add phone call' })).not.toBeInTheDocument()
  })

  it('shows add note button for agents regardless of ticket create article type', () => {
    const wrapper = renderArticleReply({
      createArticleType: 'phone',
    })

    expect(wrapper.getByRole('button', { name: 'Add internal note' })).toBeInTheDocument()
    expect(wrapper.queryByRole('button', { name: 'Add reply' })).not.toBeInTheDocument()
  })

  it('shows add reply button for customers without hint text', () => {
    const wrapper = renderArticleReply({
      isTicketCustomer: true,
      ticketArticleTypes: [
        ...defaultTicketArticleTypes,
        {
          value: 'web',
          label: 'Web',
          buttonLabel: 'Add reply',
          icon: 'web',
          fields: { attachments: {}, body: { required: true } },
          view: { agent: ['change'] },
          internal: false,
        },
      ],
    })

    expect(wrapper.getByRole('button', { name: 'Add reply' })).toBeInTheDocument()

    expect(wrapper.queryByRole('button', { name: 'Add internal note' })).not.toBeInTheDocument()
    expect(wrapper.queryByText('or use the reply actions on articles.')).not.toBeInTheDocument()
  })

  it('can display and pin reply form', async () => {
    const wrapper = renderArticleReply({
      newArticlePresent: true,
    })

    const complementary = wrapper.getByRole('complementary', {
      name: 'Reply',
    })

    expect(complementary).toHaveAttribute('aria-expanded', 'true')

    expect(
      within(complementary).getByRole('heading', {
        level: 2,
        name: 'Reply',
      }),
    ).toBeInTheDocument()

    expect(document.querySelector('#ticketArticleReplyForm')).toBeInTheDocument()

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Pin this panel' }))

    expect(complementary).toHaveAttribute('aria-expanded', 'false')

    expect(wrapper.getByRole('button', { name: 'Resize article panel' }))

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Unpin this panel' }))

    expect(complementary).toHaveAttribute('aria-expanded', 'true')
  })

  it('does not reset pinned state when form is closed and reopened', async () => {
    const wrapper = renderArticleReply({
      newArticlePresent: true,
    })

    const complementary = wrapper.getByRole('complementary', { name: 'Reply' })

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Pin this panel' }))
    expect(complementary).toHaveAttribute('aria-expanded', 'false')

    await wrapper.rerender({ newArticlePresent: false })
    await wrapper.rerender({ newArticlePresent: true })

    expect(complementary).toHaveAttribute('aria-expanded', 'false')
  })

  describe('scroll behavior on article form open', () => {
    beforeEach(() => {
      vi.clearAllMocks()
    })

    it('scrolls article panel into view when opening unpinned', async () => {
      vi.useFakeTimers()

      const wrapper = renderArticleReply({ newArticlePresent: false })

      await wrapper.rerender({ newArticlePresent: true })
      await waitForNextTick()
      vi.runAllTimers()

      expect(Element.prototype.scrollIntoView).toHaveBeenCalled()

      vi.useRealTimers()
    })

    it('does not scroll article panel into view when opening pinned', async () => {
      const wrapper = renderArticleReply({ newArticlePresent: false, pinned: true })

      await wrapper.rerender({ newArticlePresent: true })

      expect(Element.prototype.scrollIntoView).not.toHaveBeenCalled()
    })
  })

  it('renders striped border for internal articles', async () => {
    const wrapper = renderArticleReply({
      newArticlePresent: true,
      hasInternalArticle: true,
    })

    expect(wrapper.getByTestId('article-reply-stripes-panel')).toHaveClass('bg-stripes')

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Pin this panel' }))

    expect(wrapper.getByTestId('article-reply-stripes-panel')).toHaveClass('bg-stripes')

    await wrapper.rerender({
      hasInternalArticle: false,
    })

    expect(wrapper.getByTestId('article-reply-stripes-panel')).not.toHaveClass('bg-stripes')

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Unpin this panel' }))

    expect(wrapper.getByTestId('article-reply-stripes-panel')).not.toHaveClass('bg-stripes')
  })
})
