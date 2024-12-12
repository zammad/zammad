// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { renderComponent } from '#tests/support/components/index.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import ArticleReply from '../ArticleReply.vue'

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
      ticketArticleTypes: [
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
      ],
      parentReachedBottomScroll: false,
      ...props,
    },
  })

describe('ArticleReply', () => {
  it('shows common article action buttons', () => {
    const wrapper = renderArticleReply()

    expect(
      wrapper.getByRole('button', { name: 'Add internal note' }),
    ).toBeInTheDocument()

    expect(wrapper.getByIconName('pencil-square')).toBeInTheDocument()

    expect(
      wrapper.getByRole('button', { name: 'Add phone call' }),
    ).toBeInTheDocument()

    expect(wrapper.getByIconName('telephone')).toBeInTheDocument()
  })

  it('shows primary article reply action button', () => {
    const wrapper = renderArticleReply({
      createArticleType: 'phone',
    })

    expect(
      wrapper.getByRole('button', { name: 'Add reply' }),
    ).toBeInTheDocument()

    expect(wrapper.getByIconName('envelope')).toBeInTheDocument()
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

    expect(
      document.querySelector('#ticketArticleReplyForm'),
    ).toBeInTheDocument()

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'Pin this panel' }),
    )

    expect(complementary).toHaveAttribute('aria-expanded', 'false')

    expect(wrapper.getByRole('button', { name: 'Resize article panel' }))

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'Unpin this panel' }),
    )

    expect(complementary).toHaveAttribute('aria-expanded', 'true')
  })

  it('renders striped border for internal articles', async () => {
    const wrapper = renderArticleReply({
      newArticlePresent: true,
      hasInternalArticle: true,
    })

    expect(wrapper.getByTestId('article-reply-stripes-panel')).toHaveClass(
      'bg-stripes',
    )
    expect(wrapper.getByTestId('article-reply-stripes-panel')).not.toHaveClass(
      'border-stripes',
    )

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'Pin this panel' }),
    )

    expect(wrapper.getByTestId('article-reply-stripes-panel')).not.toHaveClass(
      'bg-stripes',
    )
    expect(wrapper.getByTestId('article-reply-stripes-panel')).toHaveClass(
      'border-stripes',
    )

    await wrapper.rerender({
      hasInternalArticle: false,
    })

    expect(wrapper.getByTestId('article-reply-stripes-panel')).not.toHaveClass(
      'bg-stripes',
    )
    expect(wrapper.getByTestId('article-reply-stripes-panel')).not.toHaveClass(
      'border-stripes',
    )

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'Unpin this panel' }),
    )

    expect(wrapper.getByTestId('article-reply-stripes-panel')).not.toHaveClass(
      'bg-stripes',
    )
    expect(wrapper.getByTestId('article-reply-stripes-panel')).not.toHaveClass(
      'border-stripes',
    )
  })
})
