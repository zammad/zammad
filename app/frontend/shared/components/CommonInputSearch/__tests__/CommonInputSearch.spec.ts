// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '@tests/support/components'
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

    expect(view.getByIconName('mobile-search')).toBeInTheDocument()
    expect(view.queryByIconName('mobile-close-small')).not.toBeInTheDocument()

    await view.events.type(view.getByRole('searchbox'), 'test')

    const clearButton = view.getByIconName('mobile-close-small')

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
          focus = searchInput.value!.focus
        })
        return { searchInput }
      },
    }

    const view = renderComponent(component)

    focus!()

    expect(view.getByRole('searchbox')).toHaveFocus()
  })
})
