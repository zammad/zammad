// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { onMounted, ref } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'

import CommonInputSearch, {
  type CommonInputSearchExpose,
} from '../CommonInputSearch.vue'

describe('testing input for searching', () => {
  it('renders input', async () => {
    const view = renderComponent(CommonInputSearch, {
      vModel: {
        modelValue: '',
      },
    })

    expect(view.getByIconName('search')).toBeInTheDocument()

    const search = view.getByRole('searchbox')

    expect(search).toHaveAttribute('placeholder', 'Search…')

    const clearButton = view.getByIconName('backspace2')

    expect(clearButton).toHaveClass('invisible')

    await view.events.type(search, 'test')

    expect(clearButton).not.toHaveClass('invisible')

    await view.events.click(clearButton)

    expect(search).toHaveDisplayValue('')
  })

  it('can focus outside of the component', async () => {
    let focus: () => void
    const component = {
      components: { CommonInputSearch },
      template: `<CommonInputSearch ref="searchInput" />`,
      setup() {
        const searchInput = ref<null | CommonInputSearchExpose>()
        onMounted(() => {
          ;({ focus } = searchInput.value!)
        })
        return { searchInput }
      },
    }

    const view = renderComponent(component)

    focus!()

    expect(view.getByRole('searchbox')).toHaveFocus()
  })

  it('provides search suggestion', async () => {
    const modelValue = ref('')

    const view = renderComponent(CommonInputSearch, {
      vModel: {
        modelValue,
      },
    })

    const search = view.getByRole('searchbox')

    expect(search).toHaveDisplayValue('')
    expect(view.queryByTestId('suggestion')).not.toBeInTheDocument()

    await view.events.type(search, 'foo')

    expect(modelValue.value).toBe('foo')

    await view.rerender({
      suggestion: 'foobar',
    })

    const suggestion = view.getByTestId('suggestion')

    expect(suggestion.firstChild).toHaveTextContent('foo')
    expect(suggestion.lastChild).toHaveTextContent('bar')

    await view.events.keyboard('{Tab}')

    expect(modelValue.value).toBe('foobar')
    expect(suggestion).not.toBeInTheDocument()
  })
})
