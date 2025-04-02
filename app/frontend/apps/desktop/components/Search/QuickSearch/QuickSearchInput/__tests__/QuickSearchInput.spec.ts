// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/
import { waitFor } from '@testing-library/vue'
import { ref } from 'vue'

import renderComponent, {
  getTestRouter,
} from '#tests/support/components/renderComponent.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import QuickSearchInput from '../QuickSearchInput.vue'

const renderQuickSearchInput = () => {
  const modelValue = ref('test')
  const searchActive = ref(false)

  const wrapper = renderComponent(QuickSearchInput, {
    vModel: {
      modelValue,
      searchActive,
    },
    router: true,
  })

  return { wrapper, modelValue, searchActive }
}

describe('QuickSearchInput', () => {
  it('models search value', async () => {
    const { wrapper } = renderQuickSearchInput()

    expect(wrapper.getByRole('searchbox')).toHaveValue('test')
  })

  it('shows clear input button when focused', async () => {
    const { wrapper } = renderQuickSearchInput()

    wrapper.getByRole('searchbox', { name: 'Search…' }).focus()

    await waitForNextTick()

    expect(
      wrapper.getByRole('button', { name: 'Reset Search' }),
    ).toBeInTheDocument()
  })

  it('emits search active when focused', () => {
    const { wrapper, searchActive } = renderQuickSearchInput()

    expect(searchActive.value).toBe(false)

    wrapper.getByRole('searchbox', { name: 'Search…' }).focus()

    expect(searchActive.value).toBe(true)
  })

  it('emits search active when focused', async () => {
    const { wrapper, searchActive } = renderQuickSearchInput()

    const searchField = wrapper.getByRole('searchbox', { name: 'Search…' })

    searchField.focus()

    expect(searchActive.value).toBe(true)

    await wrapper.events.type(wrapper.baseElement, '{escape}')

    expect(searchActive.value).toBe(false)

    expect(searchField).not.toHaveFocus()
  })

  it('allows clearing and resetting of the search input', async () => {
    const { wrapper, modelValue, searchActive } = renderQuickSearchInput()

    const searchField = wrapper.getByRole('searchbox', { name: 'Search…' })

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'Clear Search' }),
    )

    expect(modelValue.value).toBe('')
    expect(searchField).toHaveFocus()
    expect(searchActive.value).toBe(true)

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'Reset Search' }),
    )

    expect(searchActive.value).toBe(false)
  })

  it('redirects to search page on enter', async () => {
    const { wrapper } = renderQuickSearchInput()

    await wrapper.events.type(wrapper.getByRole('searchbox'), 'Example')
    await wrapper.events.keyboard('{enter}')

    const router = getTestRouter()

    await waitFor(() => expect(router.currentRoute.value.name).toBe('search'))

    expect(router.currentRoute.value.params).toEqual({
      searchTerm: 'testExample',
    })
  })
})
