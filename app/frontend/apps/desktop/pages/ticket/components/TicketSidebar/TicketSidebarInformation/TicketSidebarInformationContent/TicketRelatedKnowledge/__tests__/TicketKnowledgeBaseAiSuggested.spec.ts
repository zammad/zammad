// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import TicketKnowledgeBaseAiSuggested, {
  type Props,
} from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarInformation/TicketSidebarInformationContent/TicketRelatedKnowledge/TicketKnowledgeBaseAiSuggested.vue'
import { TICKET_KEY } from '#desktop/pages/ticket/composables/useTicketInformation.ts'
import {
  mockLinkAddMutation,
  waitForLinkAddMutationCalls,
} from '#desktop/pages/ticket/graphql/mutations/linkAdd.mocks.ts'
import { mockLinkListQuery } from '#desktop/pages/ticket/graphql/queries/linkList.mocks.ts'

import type { RelatedAnswer } from '../types.ts'

const ticketId = convertToGraphQLId('Ticket', 1)

const TARGET_TYPE = 'KnowledgeBase::Answer::Translation'

const renderSuggestions = (props: Partial<Props> = {}) =>
  renderComponent(TicketKnowledgeBaseAiSuggested, {
    props: {
      targetType: TARGET_TYPE,
      answers: [],
      loading: false,
      pending: false,
      hasError: false,
      errorDetail: null,
      isTicketEditable: true,
      showRelevanceScore: false,
      ...props,
    },
    provide: [
      [
        TICKET_KEY,
        {
          ticket: computed(() => ({ id: ticketId })),
          ticketId: computed(() => ticketId),
          ticketInternalId: computed(() => 1),
        },
      ],
    ],
    router: true,
    // The answer popover links to the category route.
    routerRoutes: [
      { path: '/', name: 'Root', component: { template: '<div />' } },
      {
        path: '/knowledge-base/:localeCode/category/:categoryInternalId',
        name: 'KnowledgeBaseCategory',
        component: { template: '<div />' },
      },
      // Answer links leaving the app (the public answer page) resolve to the catch-all, like they
      //   do in the real router.
      { path: '/:pathMatch(.*)*', name: 'Error', component: { template: '<div />' } },
    ],
    store: true,
  })

const relatedAnswer = (id: number, title: string, score = 90): RelatedAnswer => ({
  __typename: 'TicketAIRelatedKnowledgeBaseAnswer',
  score,
  translation: {
    __typename: 'KnowledgeBaseAnswerTranslation',
    id: convertToGraphQLId('KnowledgeBase::Answer::Translation', id),
    title,
    visibility: EnumKnowledgeBaseVisibility.Published,
    categoryTreeTranslation: [
      {
        __typename: 'KnowledgeBaseCategoryTranslation',
        id: convertToGraphQLId('KnowledgeBase::Category::Translation', 1),
        title: 'Account',
      },
    ],
    content: {
      __typename: 'KnowledgeBaseAnswerTranslationContent',
      bodyExcerpt: null,
    },
    answer: {
      __typename: 'KnowledgeBaseAnswer',
      id: convertToGraphQLId('KnowledgeBase::Answer', id),
      archivedAt: null,
      publishedAt: null,
      internalAt: null,
      tags: null,
      category: {
        __typename: 'KnowledgeBaseCategory',
        id: convertToGraphQLId('KnowledgeBase::Category', 1),
        title: 'Account',
        knowledgeBase: { __typename: 'KnowledgeBase', id: convertToGraphQLId('KnowledgeBase', 1) },
      },
    },
    kbLocale: {
      __typename: 'KnowledgeBaseLocale',
      systemLocale: { __typename: 'Locale', locale: 'en-us', name: 'English' },
    },
  },
})

describe('TicketKnowledgeBaseAiSuggested', () => {
  beforeEach(() => {
    // The link action reads/writes the ticket's link list cache.
    mockLinkListQuery({ linkList: [] })

    // Knowledge base access decides where an answer link points to.
    mockPermissions(['ticket.agent', 'knowledge_base.reader'])
  })

  it('renders the given answers as links', async () => {
    const wrapper = renderSuggestions({
      answers: [relatedAnswer(1, 'Reset your password'), relatedAnswer(2, 'Update billing')],
    })

    expect(wrapper.getByText('Suggested by AI')).toBeInTheDocument()
    expect(await wrapper.findByText('Reset your password')).toBeInTheDocument()
    expect(wrapper.getByText('Update billing')).toBeInTheDocument()

    expect(wrapper.getByText('Reset your password').closest('a')).toHaveAttribute(
      'href',
      expect.stringContaining('#knowledge_base/1/locale/en-us/answer/1'),
    )
  })

  it('links to the public answer page for a user without knowledge base permission', async () => {
    mockPermissions(['ticket.agent'])

    const wrapper = renderSuggestions({
      answers: [relatedAnswer(1, 'Reset your password')],
    })

    // Suggested answers are published for them, so the public help site can show them - the answer
    //   view of the agent interface cannot.
    expect((await wrapper.findByText('Reset your password')).closest('a')).toHaveAttribute(
      'href',
      '/help/en-us/1/1',
    )
  })

  it('keeps the BETA UI switch when the public answer page is opened', async () => {
    mockPermissions(['ticket.agent'])
    localStorage.setItem('beta-ui-switch', 'true')

    const wrapper = renderSuggestions({
      answers: [relatedAnswer(1, 'Reset your password')],
    })

    await wrapper.events.click(await wrapper.findByText('Reset your password'))

    // The public answer page is not part of the legacy app, so it needs no preparation.
    expect(localStorage.getItem('beta-ui-switch')).toBe('true')
  })

  it('shows a waiting message while the suggestions are still being generated', async () => {
    const wrapper = renderSuggestions({ pending: true })

    expect(await wrapper.findByLabelText('Searching for related answers…')).toBeInTheDocument()
  })

  it('shows the error state with a retry button', async () => {
    const wrapper = renderSuggestions({
      hasError: true,
      errorDetail: 'boom',
    })

    expect(await wrapper.findByText(/The suggestions could not be generated/)).toBeInTheDocument()
    expect(wrapper.getByText('API server error: boom')).toBeInTheDocument()
    expect(wrapper.getByRole('button', { name: 'Retry' })).toBeInTheDocument()
  })

  it('emits retry when the retry button is clicked', async () => {
    const wrapper = renderSuggestions({ hasError: true })

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Retry' }))

    expect(wrapper.emitted('retry')).toBeTruthy()
  })

  it('shows an empty message when there are no suggestions', async () => {
    const wrapper = renderSuggestions()

    expect(await wrapper.findByText('No suggestions.')).toBeInTheDocument()
  })

  it('links a suggested answer when its link action is clicked', async () => {
    mockLinkAddMutation({ linkAdd: { link: null, errors: null } })

    const wrapper = renderSuggestions({
      answers: [relatedAnswer(1, 'Reset your password')],
    })

    await wrapper.events.click(
      await wrapper.findByRole('button', { name: 'Link knowledge base answer' }),
    )

    const calls = await waitForLinkAddMutationCalls()
    expect(calls.at(-1)?.variables).toEqual({
      input: {
        sourceId: convertToGraphQLId('KnowledgeBase::Answer::Translation', 1),
        targetId: ticketId,
        type: 'normal',
      },
    })
  })

  it('clears the BETA UI switch when an answer link is followed', async () => {
    localStorage.setItem('beta-ui-switch', 'true')

    const wrapper = renderSuggestions({
      answers: [relatedAnswer(1, 'Reset your password')],
    })

    await wrapper.events.click(await wrapper.findByText('Reset your password'))

    // Otherwise the legacy answer view would redirect straight back to the new app.
    await vi.waitFor(() => expect(localStorage.getItem('beta-ui-switch')).toBeNull())
  })

  it('clears the BETA UI switch when an answer link is middle-clicked (opened in a new tab)', async () => {
    localStorage.setItem('beta-ui-switch', 'true')

    const wrapper = renderSuggestions({
      answers: [relatedAnswer(1, 'Reset your password')],
    })

    // A middle-click fires `auxclick`, not `click`.
    await wrapper.events.pointer({
      keys: '[MouseMiddle]',
      target: await wrapper.findByText('Reset your password'),
    })

    await vi.waitFor(() => expect(localStorage.getItem('beta-ui-switch')).toBeNull())
  })

  it('hides the link action when the ticket is not editable', async () => {
    const wrapper = renderSuggestions({
      answers: [relatedAnswer(1, 'Reset your password')],
      isTicketEditable: false,
    })

    await wrapper.findByText('Reset your password')

    expect(
      wrapper.queryByRole('button', { name: 'Link knowledge base answer' }),
    ).not.toBeInTheDocument()
  })

  it('shows the relevance score when the user has the right permissions', async () => {
    const wrapper = renderSuggestions({
      answers: [relatedAnswer(1, 'Reset your password', 75)],
      showRelevanceScore: true,
    })

    await wrapper.findByText('Reset your password')

    expect(wrapper.getByText('75%')).toBeInTheDocument()
  })

  it('hides the relevance score when the user does not have the right permissions', async () => {
    const wrapper = renderSuggestions({
      answers: [relatedAnswer(1, 'Reset your password', 75)],
      showRelevanceScore: false,
    })

    await wrapper.findByText('Reset your password')

    expect(wrapper.queryByText('75%')).not.toBeInTheDocument()
  })
})
