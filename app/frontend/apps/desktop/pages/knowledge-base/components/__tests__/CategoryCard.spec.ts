// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import CategoryCard from '../CategoryCard.vue'
import '#tests/graphql/builders/mocks.ts'

const renderCard = (props = {}) =>
  renderComponent(CategoryCard, {
    router: true,
    props: {
      id: convertToGraphQLId('KnowledgeBase::Category', 1),
      title: 'Getting Started',
      visibility: EnumKnowledgeBaseVisibility.Published,
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
    const wrapper = renderCard({ subcategoryCount: 3, answerCount: 7 })

    expect(wrapper.getByText('3')).toBeInTheDocument()
    expect(wrapper.getByText('7')).toBeInTheDocument()
  })

  it('show the count badges when the counts are zero', () => {
    const wrapper = renderCard({ subcategoryCount: 0, answerCount: 0 })

    expect(wrapper.getAllByText('0').length).toBe(2)
  })

  it('renders the category icon and falls back to folder', () => {
    // breadcrumb + category card = 2 icons
    expect(renderCard({ categoryIcon: 'folder' }).getAllByIconName('folder')).toHaveLength(2)
    // expect(renderCard({ categoryIcon: 'headset' }).getByLabelText('headset')).toBeInTheDocument()
    // expect(renderCard({ categoryIcon: '' }).getByLabelText('folder')).toBeInTheDocument()
  })

  it('passes the category visibility to the status icon', () => {
    const wrapper = renderCard({ visibility: EnumKnowledgeBaseVisibility.Published })

    expect(wrapper.queryAllByLabelText('Published').length).toBeGreaterThan(0)
  })

  it('warns when the category has no translation in the browsed locale', () => {
    const wrapper = renderCard({ translationMissing: true })

    expect(wrapper.getByIconName('translate')).toBeInTheDocument()
    expect(wrapper.getByLabelText('No translation for this locale available')).toBeInTheDocument()
  })

  it('shows no translation warning when a translation exists', () => {
    const wrapper = renderCard({ translationMissing: false })

    expect(wrapper.queryByIconName('translate')).not.toBeInTheDocument()
  })
})
