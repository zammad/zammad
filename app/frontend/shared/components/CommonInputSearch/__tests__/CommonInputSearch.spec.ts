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
    expect(view.queryByIconName('close-small')).not.toBeInTheDocument()

    await view.events.type(view.getByRole('searchbox'), 'test')

    const clearButton = view.getByIconName('close-small')

    expect(clearButton).toBeInTheDocument()

    await view.events.click(clearButton)

    expect(view.getByRole('searchbox')).toHaveDisplayValue('')
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
