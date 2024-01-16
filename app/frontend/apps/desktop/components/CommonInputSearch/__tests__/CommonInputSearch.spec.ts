// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { onMounted, ref } from 'vue'
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

    const clearButton = view.getByIconName('backspace')

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
})
