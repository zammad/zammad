// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { i18n } from '@shared/i18n'
import { renderComponent } from '@tests/support/components'
import type { Ref } from 'vue'
import { ref } from 'vue'
import CommonSelect, { type Props } from '../CommonSelect.vue'

const options = [
  {
    value: 0,
    label: 'Item A',
  },
  {
    value: 1,
    label: 'Item B',
  },
  {
    value: 2,
    label: 'Item C',
  },
]

const html = String.raw

const renderSelect = (props: Props, modelValue?: Ref) => {
  return renderComponent(CommonSelect, {
    props,
    slots: {
      default: html` <template #default="{ open }">
        <button @click="open()">Open Select</button>
      </template>`,
    },
    vModel: {
      modelValue,
    },
  })
}

describe('interacting with CommonSelect', () => {
  test('can select and deselect value', async () => {
    const modelValue = ref()
    const view = renderSelect({ options }, modelValue)

    await view.events.click(view.getByText('Open Select'))
    await view.events.click(view.getByText('Item A'))

    expect(view.emitted().select).toEqual([[options[0]]])

    expect(
      view.queryByTestId('dialog-overlay'),
      'dialog is hidden',
    ).not.toBeInTheDocument()

    expect(modelValue.value).toBe(0)

    await view.events.click(view.getByText('Open Select'))

    expect(
      // TODO should work just with view.getByIconName('check') with Vitest 0.19
      view.getByIconName((name, node) => {
        return (
          name === '#icon-check' &&
          !node?.parentElement?.classList.contains('invisible')
        )
      }),
    ).toBeInTheDocument()
    await view.events.click(view.getByText('Item A'))

    expect(view.emitted().select).toEqual([[options[0]], [options[0]]])
    expect(modelValue.value).toBe(undefined)
  })
  test('can select and deselect multiple values', async () => {
    const modelValue = ref()
    const view = renderSelect({ options, multiple: true }, modelValue)

    await view.events.click(view.getByText('Open Select'))
    await view.events.click(view.getByText('Item A'))

    expect(modelValue.value).toEqual([0])

    expect(view.queryAllByIconName('checked-yes')).toHaveLength(1)
    await view.events.click(view.getByText('Item A'))

    expect(modelValue.value).toEqual([])

    await view.events.click(view.getByText('Item A'))
    await view.events.click(view.getByText('Item B'))

    expect(modelValue.value).toEqual([0, 1])

    expect(view.queryAllByIconName('checked-yes')).toHaveLength(2)
  })
  test("passive mode doesn't change local value, but emits select", async () => {
    const modelValue = ref()
    const view = renderSelect({ options, passive: true }, modelValue)

    await view.events.click(view.getByText('Open Select'))
    await view.events.click(view.getByText('Item A'))

    expect(view.emitted().select).toBeDefined()

    expect(modelValue.value).toBeUndefined()
  })
  test("can't select disabled values", async () => {
    const modelValue = ref()
    const view = renderSelect(
      { options: [{ ...options[0], disabled: true }] },
      modelValue,
    )

    await view.events.click(view.getByText('Open Select'))
    await view.events.click(view.getByText('Item A'))

    expect(view.emitted().select).toBeUndefined()
    expect(modelValue.value).toBeUndefined()
  })
  test('translated values', async () => {
    i18n.setTranslationMap(new Map([[options[0].label, 'Translated Item A']]))
    const view = renderSelect({ options })

    await view.events.click(view.getByText('Open Select'))
    expect(view.getByText('Translated Item A')).toBeInTheDocument()
  })
  test("doesn't translate with no-translate prop", async () => {
    i18n.setTranslationMap(new Map([[options[0].label, 'Translated Item A']]))
    const view = renderSelect({ options, noOptionsLabelTranslation: true })

    await view.events.click(view.getByText('Open Select'))
    expect(view.getByText(/^Item A$/)).toBeInTheDocument()
  })
  // TODO e2e test on keyboard interaction (select with space, moving up/down)
})
