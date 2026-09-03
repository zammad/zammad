// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import buildIconsQueries from '#tests/support/components/iconQueries.ts'
import renderComponent from '#tests/support/components/renderComponent.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { EnumTextDirection } from '#shared/graphql/types.ts'
import { convertToGraphQLId, getIdFromGraphQLId } from '#shared/graphql/utils.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'

import KnowledgeBaseAnswerStepper, { type Props } from '../KnowledgeBaseAnswerStepper.vue'

import type { KnowledgeBaseAnswerHeader } from '../../../types.ts'

const PREVIOUS_ANSWER_ID = convertToGraphQLId('KnowledgeBase::Answer', 4)
const NEXT_ANSWER_ID = convertToGraphQLId('KnowledgeBase::Answer', 6)

type Navigation = NonNullable<NonNullable<KnowledgeBaseAnswerHeader['translation']>['navigation']>

const navigation: Navigation = {
  __typename: 'KnowledgeBaseAnswerNavigation',
  index: 6,
  totalCount: 17,
  previousAnswer: {
    __typename: 'KnowledgeBaseAnswer',
    id: PREVIOUS_ANSWER_ID,
    translation: {
      __typename: 'KnowledgeBaseAnswerTranslation',
      id: convertToGraphQLId('KnowledgeBase::Answer::Translation', 4),
      title: 'Previous answer',
    },
  },
  nextAnswer: {
    __typename: 'KnowledgeBaseAnswer',
    id: NEXT_ANSWER_ID,
    translation: {
      __typename: 'KnowledgeBaseAnswerTranslation',
      id: convertToGraphQLId('KnowledgeBase::Answer::Translation', 6),
      title: 'Next answer',
    },
  },
}

const renderStepper = (props: Partial<Props> = {}) =>
  renderComponent(KnowledgeBaseAnswerStepper, {
    router: true,
    routerRoutes: [
      { path: '/', component: { template: '<div />' } },
      {
        name: 'KnowledgeBaseAnswer',
        path: '/knowledge-base/locale/:localeCode/answer/:answerInternalId',
        component: { template: '<div />' },
      },
    ],
    props: {
      navigation,
      localeCode: 'en-us',
      ...props,
    },
  })

describe('KnowledgeBaseAnswerStepper', () => {
  it('renders the position and accessible neighbor labels', () => {
    const view = renderStepper()

    const answerNavigation = view.getByRole('navigation', { name: 'Answer navigation' })

    expect(answerNavigation).toBeInTheDocument()
    expect(answerNavigation).toHaveTextContent('6/17')
    expect(view.getByRole('link', { name: 'Previous answer: Previous answer' })).toBeInTheDocument()
    expect(view.getByRole('link', { name: 'Next answer: Next answer' })).toBeInTheDocument()
  })

  it('does not render for a single answer', () => {
    const view = renderStepper({
      navigation: { ...navigation, totalCount: 1 },
    })

    expect(view.queryByRole('navigation', { name: 'Answer navigation' })).not.toBeInTheDocument()
  })

  it('routes to each neighbor', async () => {
    const view = renderStepper()

    await view.events.click(view.getByRole('link', { name: 'Previous answer: Previous answer' }))
    await waitFor(() => {
      expect(view).toHaveCurrentUrl(
        `/knowledge-base/locale/en-us/answer/${getIdFromGraphQLId(PREVIOUS_ANSWER_ID)}`,
      )
    })

    await view.events.click(view.getByRole('link', { name: 'Next answer: Next answer' }))
    await waitFor(() => {
      expect(view).toHaveCurrentUrl(
        `/knowledge-base/locale/en-us/answer/${getIdFromGraphQLId(NEXT_ANSWER_ID)}`,
      )
    })
  })

  it('reverses the chevrons in RTL locales', async () => {
    const view = renderStepper()
    const locale = useLocaleStore()

    const previousLink = view.getByRole('link', { name: 'Previous answer: Previous answer' })
    const nextLink = view.getByRole('link', { name: 'Next answer: Next answer' })

    expect(buildIconsQueries(previousLink).getByIconName('chevron-left')).toBeInTheDocument()
    expect(buildIconsQueries(nextLink).getByIconName('chevron-right')).toBeInTheDocument()

    locale.localeData = { dir: EnumTextDirection.Rtl } as never

    await waitFor(() => {
      expect(buildIconsQueries(previousLink).getByIconName('chevron-right')).toBeInTheDocument()
      expect(buildIconsQueries(nextLink).getByIconName('chevron-left')).toBeInTheDocument()
    })
  })
})
