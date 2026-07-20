// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import AnswerCard from '../AnswerCard.vue'

const renderCard = (props = {}) =>
  renderComponent(AnswerCard, {
    props: {
      id: convertToGraphQLId('KnowledgeBase:: Answer', 1),
      title: 'Getting Started',
      visibility: EnumKnowledgeBaseVisibility.Public,
      translationMissing: false,
      position: 0,
      ...props,
    },
  })

describe('AnswerCard', () => {
  it('renders the answer title', () => {
    expect(
      renderCard({ title: 'Reset your password' }).getByText('Reset your password'),
    ).toBeInTheDocument()
  })

  it('passes the answer visibility to the status icon', () => {
    const view = renderCard({ visibility: EnumKnowledgeBaseVisibility.Internal })

    expect(view.queryAllByLabelText('Internal').length).toBeGreaterThan(0)
  })

  it('warns when the answer has no translation in the browsed locale', () => {
    const view = renderCard({ translationMissing: true })

    expect(view.getByIconName('exclamation-triangle')).toBeInTheDocument()
    expect(view.getByLabelText('No translation for this locale available')).toBeInTheDocument()
  })

  it('shows no translation warning when a translation exists', () => {
    const view = renderCard({ translationMissing: false })

    expect(view.queryByIconName('exclamation-triangle')).not.toBeInTheDocument()
  })
})
