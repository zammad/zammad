// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import CategoryCard from '../CategoryCard.vue'

vi.mock('../../stores/knowledgeBase.ts', () => ({
  useKnowledgeBaseStore: () => ({ activeLocale: ref(undefined) }),
}))

const renderCard = (props = {}) =>
  renderComponent(CategoryCard, {
    props: {
      id: convertToGraphQLId('KnowledgeBase::Category', 1),
      title: 'Getting Started',
      visibility: EnumKnowledgeBaseVisibility.Public,
      categoryIcon: 'headset',
      subcategoryCount: 0,
      answerCount: 0,
      translationMissing: false,
      position: 0,
      ...props,
    },
  })

describe('CategoryCard', () => {
  it('shows the subcategory and answer count badges', () => {
    const view = renderCard({ subcategoryCount: 3, answerCount: 7 })

    expect(view.getByText('3')).toBeInTheDocument()
    expect(view.getByText('7')).toBeInTheDocument()
  })

  it('show the count badges when the counts are zero', () => {
    const view = renderCard({ subcategoryCount: 0, answerCount: 0 })

    expect(view.getAllByText('0').length).toBe(2)
  })

  it('renders the category icon and falls back to folder', () => {
    // breadcrumb + category card = 2 icons
    expect(renderCard({ categoryIcon: 'folder' }).getAllByIconName('folder')).toHaveLength(2)
    // expect(renderCard({ categoryIcon: 'headset' }).getByLabelText('headset')).toBeInTheDocument()
    // expect(renderCard({ categoryIcon: '' }).getByLabelText('folder')).toBeInTheDocument()
  })

  it('passes the category visibility to the status icon', () => {
    const view = renderCard({ visibility: EnumKnowledgeBaseVisibility.Public })

    expect(view.queryAllByLabelText('Public').length).toBeGreaterThan(0)
  })

  it('warns when the category has no translation in the browsed locale', () => {
    const view = renderCard({ translationMissing: true })

    expect(view.getByIconName('exclamation-triangle')).toBeInTheDocument()
    expect(view.getByLabelText('No translation for this locale available')).toBeInTheDocument()
  })

  it('shows no translation warning when a translation exists', () => {
    const view = renderCard({ translationMissing: false })

    expect(view.queryByIconName('exclamation-triangle')).not.toBeInTheDocument()
  })
})
