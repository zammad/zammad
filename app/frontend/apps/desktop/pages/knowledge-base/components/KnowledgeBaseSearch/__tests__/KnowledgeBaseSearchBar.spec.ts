// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'

import KnowledgeBaseSearchBar from '../KnowledgeBaseSearchBar.vue'

const renderSearchBar = (
  options: { title?: string; search?: ReturnType<typeof ref<string>> } = {},
) => {
  const search = options.search ?? ref('')

  const view = renderComponent(KnowledgeBaseSearchBar, {
    props: { title: options.title ?? 'My Knowledge Base' },
    vModel: { modelValue: search },
  })

  return { view, search, input: view.getByRole('searchbox') }
}

describe('KnowledgeBaseSearchBar', () => {
  it('says which node it searches', () => {
    const { input } = renderSearchBar({ title: 'Some Internal Category' })

    expect(input).toHaveAttribute('placeholder', 'Search within Some Internal Category…')
  })

  it('hands the typed term to its model', async () => {
    const { view, search, input } = renderSearchBar()

    await view.events.type(input, 'printer')

    expect(search.value).toBe('printer')
  })

  it('empties the model from the clear button', async () => {
    const { view, search, input } = renderSearchBar({ search: ref('printer') })

    expect(input).toHaveValue('printer')

    await view.events.click(view.getByLabelText('Clear search'))

    expect(search.value).toBe('')
  })

  it('empties the model on escape', async () => {
    const { view, search, input } = renderSearchBar({ search: ref('printer') })

    await view.events.type(input, '{Escape}')

    expect(search.value).toBe('')
  })
})
