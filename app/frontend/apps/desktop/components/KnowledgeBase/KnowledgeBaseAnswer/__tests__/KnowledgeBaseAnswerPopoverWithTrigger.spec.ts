// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { KnowledgeBaseAnswerInfoForPopoverDocument } from '../KnowledgeBaseAnswerPopoverWithTrigger/graphql/queries/knowledgeBaseAnswerInfoForPopover.api.ts'
import {
  mockKnowledgeBaseAnswerInfoForPopoverQuery,
  waitForKnowledgeBaseAnswerInfoForPopoverQueryCalls,
} from '../KnowledgeBaseAnswerPopoverWithTrigger/graphql/queries/knowledgeBaseAnswerInfoForPopover.mocks.ts'
import KnowledgeBaseAnswerPopoverWithTrigger from '../KnowledgeBaseAnswerPopoverWithTrigger.vue'

const ANSWER_ID = convertToGraphQLId('KnowledgeBase::Answer', 1)
const CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 42)
const LOCALE = 'en-gb'

const mockAnswer = () =>
  mockKnowledgeBaseAnswerInfoForPopoverQuery({
    knowledgeBaseAnswer: {
      id: ANSWER_ID,
      translation: {
        id: convertToGraphQLId('KnowledgeBase::Answer::Translation', 1),
        title: 'Ocarina tuning',
        visibility: EnumKnowledgeBaseVisibility.Published,
        categoryTreeTranslation: [
          {
            id: convertToGraphQLId('KnowledgeBase::Category::Translation', 42),
            title: 'Instruments',
          },
        ],
        content: { bodyExcerpt: 'Hold the ocarina with both hands.' },
        answer: {
          id: ANSWER_ID,
          archivedAt: null,
          publishedAt: '2024-01-01T00:00:00Z',
          internalAt: null,
          tags: null,
          category: { id: CATEGORY_ID },
        },
        kbLocale: {
          systemLocale: { locale: LOCALE, name: 'English (GB)' },
        },
      },
    },
  })

const renderTrigger = () =>
  renderComponent(KnowledgeBaseAnswerPopoverWithTrigger, {
    props: {
      answerId: ANSWER_ID,
      locale: LOCALE,
      triggerLink: '/help/en-gb/42/1',
    },
    slots: { default: 'Ocarina tuning' },
    router: true,
    routerRoutes: [
      { path: '/', name: 'Root', component: { template: '<div />' } },
      {
        path: '/knowledge-base/:localeCode/category/:categoryInternalId',
        name: 'KnowledgeBaseCategory',
        component: { template: '<div />' },
      },
      // Tags link into the detailed search.
      { path: '/search/:searchTerm?', name: 'Search', component: { template: '<div />' } },
      { path: '/:pathMatch(.*)*', name: 'Error', component: { template: '<div />' } },
    ],
    store: true,
  })

describe('KnowledgeBaseAnswerPopoverWithTrigger', () => {
  beforeEach(() => {
    mockPermissions(['ticket.agent', 'knowledge_base.reader'])
  })

  // The point of the whole wrapper: the quicksearch group renders ten of these and must not fetch
  //   a popover's worth of data for any of them until one is opened.
  it('does not fetch the answer before the popover is opened', () => {
    mockAnswer()

    const wrapper = renderTrigger()

    expect(wrapper.getByRole('link', { name: 'Ocarina tuning' })).toBeInTheDocument()
    expect(getGraphQLMockCalls(KnowledgeBaseAnswerInfoForPopoverDocument)).toHaveLength(0)
  })

  it('fetches the answer when the popover opens', async () => {
    mockAnswer()

    const wrapper = renderTrigger()

    await wrapper.events.hover(wrapper.getByRole('link'))

    const calls = await waitForKnowledgeBaseAnswerInfoForPopoverQueryCalls()

    expect(calls).toHaveLength(1)
  })

  // The item that opened the popover names a locale, and a search hit can come from a locale other
  //   than the reader's preferred one - so the popover has to describe the translation it was
  //   opened from rather than resolving its own.
  it('asks for the translation in the locale it was given', async () => {
    mockAnswer()

    const wrapper = renderTrigger()

    await wrapper.events.hover(wrapper.getByRole('link'))

    const calls = await waitForKnowledgeBaseAnswerInfoForPopoverQueryCalls()

    expect(calls.at(-1)?.variables).toEqual({ answerId: ANSWER_ID, locale: LOCALE })
  })

  // Both halves of the lazy load in one example, because the second only means something after the
  //   first: the popover opens on a skeleton and swaps it for the answer when the query answers.
  it('shows a skeleton until the answer arrives, then the details', async () => {
    mockAnswer()

    const wrapper = renderTrigger()

    await wrapper.events.hover(wrapper.getByRole('link'))

    const popover = await wrapper.findByRole('region')

    expect(within(popover).getAllByRole('progressbar').length).toBeGreaterThan(0)

    expect(await within(popover).findByText('Ocarina tuning')).toBeVisible()

    expect(within(popover).queryAllByRole('progressbar')).toHaveLength(0)
    expect(within(popover).getByText('Hold the ocarina with both hands.')).toBeVisible()
    expect(within(popover).getByText('Language')).toBeVisible()
    expect(within(popover).getByRole('link', { name: 'Instruments' })).toBeVisible()
  })

  // Deliberately not gated on `knowledge_base.*`, unlike the ticket sidebar's answer list: here the
  //   caller only offers answers the user may already see. What a customer may not see is dropped
  //   by the server (`internalAt` and `archivedAt` are scoped fields), not by hiding the popover -
  //   which would leave them with a bare title.
  it('shows the details to a user without any knowledge base permission', async () => {
    mockPermissions(['ticket.customer'])
    mockKnowledgeBaseAnswerInfoForPopoverQuery({
      knowledgeBaseAnswer: {
        id: ANSWER_ID,
        translation: {
          title: 'Ocarina tuning',
          visibility: EnumKnowledgeBaseVisibility.Published,
          categoryTreeTranslation: [
            {
              id: convertToGraphQLId('KnowledgeBase::Category::Translation', 42),
              title: 'Instruments',
            },
          ],
          content: { bodyExcerpt: 'Hold the ocarina with both hands.' },
          answer: {
            id: ANSWER_ID,
            // What the server hands a customer: the editorial dates are denied, publication is not.
            archivedAt: null,
            internalAt: null,
            publishedAt: '2024-01-01T00:00:00Z',
            tags: null,
            category: { id: CATEGORY_ID },
          },
          kbLocale: { systemLocale: { locale: LOCALE, name: 'English (GB)' } },
        },
      },
    })

    const wrapper = renderTrigger()

    await wrapper.events.hover(wrapper.getByRole('link'))

    const popover = await wrapper.findByRole('region')

    expect(await within(popover).findByText('Ocarina tuning')).toBeVisible()
    expect(within(popover).getByText('Published')).toBeVisible()
    expect(within(popover).getByText('Language')).toBeVisible()
    expect(within(popover).queryByText('Internally published')).not.toBeInTheDocument()
    expect(within(popover).queryByText('Archived')).not.toBeInTheDocument()
  })
})
