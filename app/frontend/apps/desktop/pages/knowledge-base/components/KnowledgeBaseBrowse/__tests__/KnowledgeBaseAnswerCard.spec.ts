// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import '#tests/graphql/builders/mocks.ts'

import { flushPromises } from '@vue/test-utils'

import renderComponent, { getTestRouter } from '#tests/support/components/renderComponent.ts'

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import KnowledgeBaseAnswerCard from '../KnowledgeBaseAnswerCard.vue'

const routerRoutes = [
  { name: 'Dashboard', path: '/', component: { template: '<div />' } },
  {
    name: 'KnowledgeBaseCategory',
    path: '/knowledge-base/locale/:localeCode/category/:categoryInternalId(\\d+)',
    component: { template: '<div />' },
  },
  {
    name: 'KnowledgeBaseAnswer',
    path: '/knowledge-base/locale/:localeCode/answer/:answerInternalId(\\d+)',
    component: { template: '<div />' },
  },
]

// The card takes the locale from the browsed URL; the test router only exists
//   after the first render, so the route is set afterwards.
const renderCard = async (props = {}, path = '/knowledge-base/locale/en-us/category/1') => {
  const wrapper = renderComponent(KnowledgeBaseAnswerCard, {
    router: true,
    routerRoutes,
    props: {
      id: convertToGraphQLId('KnowledgeBase::Answer', 1),
      title: 'Getting Started',
      visibility: EnumKnowledgeBaseVisibility.Published,
      translationMissing: false,
      position: 0,
      ...props,
    },
  })

  await getTestRouter().push(path)
  await flushPromises()

  return wrapper
}

describe('KnowledgeBaseAnswerCard', () => {
  it('renders the answer title', async () => {
    const wrapper = await renderCard({ title: 'Reset your password' })

    expect(wrapper.getByText('Reset your password')).toBeInTheDocument()
  })

  it('links to the answer of the browsed locale', async () => {
    const wrapper = await renderCard({ id: convertToGraphQLId('KnowledgeBase::Answer', 42) })

    expect(wrapper.getByRole('link')).toHaveAttribute(
      'href',
      '/desktop/knowledge-base/locale/en-us/answer/42',
    )
  })

  it('renders no link without a browsed locale', async () => {
    const wrapper = await renderCard({}, '/')

    expect(wrapper.queryByRole('link')).not.toBeInTheDocument()
    expect(wrapper.getByText('Getting Started')).toBeInTheDocument()
  })

  it('passes the answer visibility to the status icon', async () => {
    const wrapper = await renderCard({ visibility: EnumKnowledgeBaseVisibility.Internal })

    expect(wrapper.getByIconName('kb-internal')).toBeInTheDocument()
  })

  it('warns when the answer has no translation in the browsed locale', async () => {
    const wrapper = await renderCard({ translationMissing: true })

    expect(wrapper.getByIconName('translate')).toBeInTheDocument()
    expect(wrapper.getByLabelText('No translation available for this locale')).toBeInTheDocument()
  })

  it('shows no translation warning when a translation exists', async () => {
    const wrapper = await renderCard({ translationMissing: false })

    expect(wrapper.queryByIconName('translate')).not.toBeInTheDocument()
  })
})
