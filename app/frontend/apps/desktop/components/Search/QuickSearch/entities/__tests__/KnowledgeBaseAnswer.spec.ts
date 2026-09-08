// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import '#tests/graphql/builders/mocks.ts'

import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { convertToGraphQLId, getIdFromGraphQLId } from '#shared/graphql/utils.ts'

import { waitForKnowledgeBaseAnswerInfoForPopoverQueryCalls } from '#desktop/components/KnowledgeBase/KnowledgeBaseAnswer/KnowledgeBaseAnswerPopoverWithTrigger/graphql/queries/knowledgeBaseAnswerInfoForPopover.mocks.ts'

import KnowledgeBaseAnswer from '../KnowledgeBaseAnswer.vue'

const LOCALE = 'en-us'

const answerTranslation = (
  id: number,
  title: string,
  visibility = EnumKnowledgeBaseVisibility.Published,
) => ({
  __typename: 'KnowledgeBaseAnswerTranslation' as const,
  id: convertToGraphQLId('KnowledgeBase::Answer::Translation', id),
  title,
  visibility,
  kbLocale: { systemLocale: { locale: LOCALE } },
  answer: {
    id: convertToGraphQLId('KnowledgeBase::Answer', id),
    category: { id: convertToGraphQLId('KnowledgeBase::Category', 7) },
  },
})

const renderAnswer = (item: ReturnType<typeof answerTranslation>) =>
  renderComponent(KnowledgeBaseAnswer, {
    props: {
      item,
      // The singular literal QuickSearchResultList actually passes, which does not match the
      //   `QuickSearchPluginProps` union's `'quick-search-results'`. Pinned so nothing here starts
      //   branching on a value that never arrives.
      mode: 'quick-search-result',
    },
    router: true,
    routerRoutes: [
      { path: '/', name: 'Dashboard', component: { template: '<div />' } },
      {
        path: '/knowledge-base/locale/:localeCode/answer/:answerInternalId',
        name: 'KnowledgeBaseAnswer',
        component: { template: '<div />' },
      },
      // The public answer page leaves the app, so it resolves to the catch-all here just as it
      //   does in the real router.
      { path: '/:pathMatch(.*)*', name: 'Error', component: { template: '<div />' } },
    ],
    store: true,
  })

describe('KnowledgeBaseAnswer quicksearch item', () => {
  beforeEach(() => {
    mockPermissions(['ticket.agent', 'knowledge_base.reader'])
    // The group is only ever shown while a knowledge base is browsable, and that is also what
    //   decides where an answer link points - see getKnowledgeBaseAnswerLink.
    mockApplicationConfig({ kb_active: true })
  })

  it('renders the answer title', () => {
    const wrapper = renderAnswer(answerTranslation(1, 'Ocarina tuning'))

    expect(wrapper.getByText('Ocarina tuning')).toBeInTheDocument()
  })

  it('renders the publication state as an icon', () => {
    const wrapper = renderAnswer(
      answerTranslation(1, 'Internal runbook', EnumKnowledgeBaseVisibility.Internal),
    )

    expect(wrapper.getByIconName('kb-internal')).toBeInTheDocument()
  })

  it('links to the answer view for a user who may browse the knowledge base', () => {
    const item = answerTranslation(1, 'Ocarina tuning')

    const wrapper = renderAnswer(item)

    expect(wrapper.getByText('Ocarina tuning').closest('a')).toHaveAttribute(
      'href',
      `/desktop/knowledge-base/locale/${LOCALE}/answer/${getIdFromGraphQLId(item.answer.id)}`,
    )
  })

  // A customer reads the answer inside Zammad, not on the public help site. The answer route is
  //   guarded by `canBrowse` rather than by a knowledge base permission, so whenever a customer can
  //   see this group at all they can open that route too.
  it('links a customer to the answer inside Zammad', () => {
    mockPermissions(['ticket.customer'])
    mockApplicationConfig({ kb_active: true, kb_active_publicly: true })

    const item = answerTranslation(3, 'Ocarina tuning')

    const wrapper = renderAnswer(item)

    expect(wrapper.getByText('Ocarina tuning').closest('a')).toHaveAttribute(
      'href',
      `/desktop/knowledge-base/locale/${LOCALE}/answer/${getIdFromGraphQLId(item.answer.id)}`,
    )
  })

  // The one case the public help site is still the answer for: no browsable knowledge base, where
  //   the in-app route would refuse them.
  it('falls back to the public help page when no knowledge base is browsable', () => {
    mockPermissions(['ticket.customer'])
    mockApplicationConfig({ kb_active: false, kb_active_publicly: false })

    const wrapper = renderAnswer(answerTranslation(3, 'Ocarina tuning'))

    expect(wrapper.getByText('Ocarina tuning').closest('a')).toHaveAttribute(
      'href',
      `/help/${LOCALE}/7/3`,
    )
  })

  // The details popover itself is covered on the shared component
  //   (components/KnowledgeBaseAnswer/__tests__/KnowledgeBaseAnswerPopoverWithTrigger.spec.ts);
  //   what matters here is that the item hands it the right answer - the translation carries an id
  //   of its own, and a locale that need not be the reader's preferred one.
  it('opens the details popover for its own answer and locale', async () => {
    const item = answerTranslation(5, 'Ocarina tuning')

    const wrapper = renderAnswer(item)

    await wrapper.events.hover(wrapper.getByRole('link'))

    const calls = await waitForKnowledgeBaseAnswerInfoForPopoverQueryCalls()

    expect(calls.at(-1)?.variables).toEqual({ answerId: item.answer.id, locale: LOCALE })
  })

  // The item is a translation, so both ids are in scope and only one of them addresses the answer.
  it('builds the link from the answer id, not the translation id', () => {
    const item = answerTranslation(1, 'Ocarina tuning')
    item.answer.id = convertToGraphQLId('KnowledgeBase::Answer', 42)

    const wrapper = renderAnswer(item)

    expect(wrapper.getByText('Ocarina tuning').closest('a')).toHaveAttribute(
      'href',
      `/desktop/knowledge-base/locale/${LOCALE}/answer/42`,
    )
  })
})
