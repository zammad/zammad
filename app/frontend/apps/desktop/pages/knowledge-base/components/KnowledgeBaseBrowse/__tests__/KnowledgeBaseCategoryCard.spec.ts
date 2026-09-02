// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { convertToGraphQLId, getIdFromGraphQLId } from '#shared/graphql/utils.ts'

import KnowledgeBaseCategoryCard from '../KnowledgeBaseCategoryCard.vue'
import '#tests/graphql/builders/mocks.ts'

const CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 1)

const routerRoutes = [
  { name: 'Dashboard', path: '/', component: { template: '<div />' } },
  {
    name: 'KnowledgeBaseCategory',
    path: '/knowledge-base/locale/:localeCode/category/:categoryInternalId(\\d+)',
    component: { template: '<div />' },
  },
  {
    name: 'KnowledgeBaseAnswerCreate',
    path: '/knowledge-base/locale/:localeCode/answer/create/:tabId?',
    component: { template: '<div />' },
  },
]

const renderCard = (props = {}) =>
  renderComponent(KnowledgeBaseCategoryCard, {
    router: true,
    routerRoutes,
    props: {
      id: CATEGORY_ID,
      title: 'Getting Started',
      visibility: EnumKnowledgeBaseVisibility.Published,
      categoryIcon: 'f004',
      iconSet: 'FontAwesome',
      subcategoryCount: 0,
      answerCount: 0,
      translationMissing: false,
      position: 0,
      isDeletable: true,
      policy: { update: true, destroy: true, createSubcategory: true, createAnswer: true },
      ...props,
    },
  })

describe('KnowledgeBaseCategoryCard', () => {
  it('shows the subcategory and answer count badges', () => {
    const wrapper = renderCard({ subcategoryCount: 3, answerCount: 7 })

    expect(wrapper.getByText('3')).toBeInTheDocument()
    expect(wrapper.getByText('7')).toBeInTheDocument()
  })

  it('show the count badges when the counts are zero', () => {
    const wrapper = renderCard({ subcategoryCount: 0, answerCount: 0 })

    expect(wrapper.getAllByText('0').length).toBe(2)
  })

  it('renders the category icon', () => {
    const wrapper = renderCard({ categoryIcon: 'f115', iconSet: 'FontAwesome' })

    const svgElement = wrapper.container.querySelector('svg')!

    expect(svgElement.querySelector('use')?.getAttribute('href')).toContain(
      'FontAwesome.svg#icon-f115',
    )
  })

  it('passes the category visibility to the status icon', () => {
    const wrapper = renderCard({ visibility: EnumKnowledgeBaseVisibility.Published })

    expect(wrapper.queryAllByLabelText('Published').length).toBeGreaterThan(0)
  })

  it('warns when the category has no translation in the browsed locale', () => {
    const wrapper = renderCard({ translationMissing: true })

    expect(wrapper.getByIconName('translate')).toBeInTheDocument()
    expect(wrapper.getByLabelText('No translation available for this locale')).toBeInTheDocument()
  })

  it('shows no translation warning when a translation exists', () => {
    const wrapper = renderCard({ translationMissing: false })

    expect(wrapper.queryByIconName('translate')).not.toBeInTheDocument()
  })

  describe('action menu', () => {
    // The router is shared by the whole file, so the navigating case has to hand the next one
    //   back a route the card can read a locale off.
    afterEach(async () => {
      await getTestRouter().replace('/')
    })

    const openMenu = async (props = {}) => {
      const wrapper = renderCard(props)

      await wrapper.events.click(wrapper.getByRole('button', { name: 'Category actions' }))

      return wrapper
    }

    it('offers starting an answer in the category', async () => {
      const wrapper = await openMenu()

      expect(await wrapper.findByText('Add answer')).toBeInTheDocument()
    })

    it('does not offer starting an answer without that policy', async () => {
      const wrapper = await openMenu({
        policy: { update: true, destroy: true, createSubcategory: true, createAnswer: false },
      })

      expect(await wrapper.findByText('Add sub-category')).toBeInTheDocument()
      expect(wrapper.queryByText('Add answer')).not.toBeInTheDocument()
    })

    it('opens a fresh draft for the category it was clicked in', async () => {
      const router = getTestRouter()

      await router.push('/knowledge-base/locale/en-us/category/1')

      const wrapper = await openMenu()

      await wrapper.events.click(await wrapper.findByText('Add answer'))

      await waitFor(() => {
        expect(router.currentRoute.value.name).toBe('KnowledgeBaseAnswerCreate')
      })

      const { params, query } = router.currentRoute.value

      expect(params.localeCode).toBe('en-us')
      expect(query.categoryId).toBe(String(getIdFromGraphQLId(CATEGORY_ID)))
      expect(params.tabId, 'a fresh draft every time').toBeTruthy()
    })

    it('offers adding a sub-category below the parent category', async () => {
      const wrapper = await openMenu()

      expect(await wrapper.findByText('Add sub-category')).toBeInTheDocument()
    })

    it('does not offer adding a sub-category without that policy', async () => {
      const wrapper = await openMenu({
        policy: { update: true, destroy: true, createSubcategory: false, createAnswer: false },
      })

      expect(await wrapper.findByText('Edit category')).toBeInTheDocument()
      expect(wrapper.queryByText('Add sub-category')).not.toBeInTheDocument()
    })

    // `update` is the same predicate today, but a deliberately separate policy method — a
    //   category one may only create below still gets a menu.
    it('offers it alone when the category may only be created below', async () => {
      const wrapper = await openMenu({
        policy: { update: false, destroy: false, createSubcategory: true, createAnswer: false },
      })

      expect(await wrapper.findByText('Add sub-category')).toBeInTheDocument()
      expect(wrapper.queryByText('Edit category')).not.toBeInTheDocument()
      expect(wrapper.queryByText('Delete category')).not.toBeInTheDocument()
    })

    it('lists creating before the actions on the category itself', async () => {
      const wrapper = await openMenu()

      const items = await wrapper.findAllByTestId('popover-menu-item')

      expect(items.map((item) => item.textContent?.trim())).toEqual([
        'Add answer',
        'Add sub-category',
        'Edit category',
        'Delete category',
      ])
    })

    it('renders no menu for a category the user may only read', () => {
      const wrapper = renderCard({
        policy: { update: false, destroy: false, createSubcategory: false, createAnswer: false },
      })

      expect(wrapper.queryByRole('button', { name: 'Category actions' })).not.toBeInTheDocument()
    })
  })
})
