// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { i18n } from '#shared/i18n.ts'
import { renderComponent } from '#tests/support/components/index.ts'
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
      default: html` <template #default="{ open, focus }">
        <button @click="open()">Open Select</button>
        <button @click="focus()">Move Focus</button>
      </template>`,
    },
    vModel: {
      modelValue,
    },
  })
}

beforeEach(() => {
  i18n.setTranslationMap(new Map([]))
})

describe('CommonSelect.vue', () => {
  it('can select and unselect value', async () => {
    const modelValue = ref()
    const view = renderSelect({ options }, modelValue)

    await view.events.click(view.getByText('Open Select'))
    await view.events.click(view.getByText('Item A'))

    expect(view.emitted().select).toEqual([[options[0]]])

    expect(
      view.queryByRole('menu'),
      'dropdown is hidden',
    ).not.toBeInTheDocument()

    expect(modelValue.value).toBe(0)

    await view.events.click(view.getByText('Open Select'))

    expect(
      view.getByIconName((name, node) => {
        return (
          name === '#icon-check2' &&
          !node?.parentElement?.classList.contains('invisible')
        )
      }),
    ).toBeInTheDocument()

    await view.events.click(view.getByText('Item A'))

    expect(view.emitted().select).toEqual([[options[0]], [options[0]]])
    expect(modelValue.value).toBe(undefined)
  })

  it('does not close select with noClose prop', async () => {
    const view = renderSelect({ options, noClose: true })

    await view.events.click(view.getByText('Open Select'))
    await view.events.click(view.getByRole('option', { name: 'Item A' }))

    expect(view.getByRole('menu')).toBeInTheDocument()
  })

  it('can select and unselect multiple values', async () => {
    const modelValue = ref()
    const view = renderSelect({ options, multiple: true }, modelValue)

    await view.events.click(view.getByText('Open Select'))
    await view.events.click(view.getByText('Item A'))

    expect(modelValue.value).toEqual([0])

    expect(view.queryAllByIconName('check-square')).toHaveLength(1)
    await view.events.click(view.getByText('Item A'))

    expect(modelValue.value).toEqual([])

    await view.events.click(view.getByText('Item A'))
    await view.events.click(view.getByText('Item B'))

    expect(modelValue.value).toEqual([0, 1])

    expect(view.queryAllByIconName('check-square')).toHaveLength(2)
  })

  it('passive mode does not change local value, but emits select', async () => {
    const modelValue = ref()
    const view = renderSelect({ options, passive: true }, modelValue)

    await view.events.click(view.getByText('Open Select'))
    await view.events.click(view.getByText('Item A'))

    expect(view.emitted().select).toBeDefined()

    expect(modelValue.value).toBeUndefined()
  })

  it('cannot select disabled values', async () => {
    const modelValue = ref()
    const view = renderSelect(
      { options: [{ ...options[0], disabled: true }] },
      modelValue,
    )

    await view.events.click(view.getByText('Open Select'))

    expect(view.getByRole('option')).toHaveAttribute('aria-disabled', 'true')

    await view.events.click(view.getByText('Item A'))

    expect(view.emitted().select).toBeUndefined()
    expect(modelValue.value).toBeUndefined()
  })

  it('translates labels', async () => {
    i18n.setTranslationMap(new Map([[options[0].label, 'Translated Item A']]))
    const view = renderSelect({ options })

    await view.events.click(view.getByText('Open Select'))
    expect(view.getByText('Translated Item A')).toBeInTheDocument()
  })

  it('does not translate with noOptionsLabelTranslation prop', async () => {
    i18n.setTranslationMap(new Map([[options[0].label, 'Translated Item A']]))
    const view = renderSelect({ options, noOptionsLabelTranslation: true })

    await view.events.click(view.getByText('Open Select'))
    expect(view.getByText(/^Item A$/)).toBeInTheDocument()
  })

  it('can use boolean as value', async () => {
    const modelValue = ref()
    const view = renderSelect(
      {
        options: [
          { value: true, label: 'Yes' },
          { value: false, label: 'No' },
        ],
      },
      modelValue,
    )
    await view.events.click(view.getByText('Open Select'))
    await view.events.click(view.getByText('Yes'))
    expect(modelValue.value).toBe(true)
  })

  it('has an accessible name', async () => {
    const view = renderSelect({ options })

    await view.events.click(view.getByText('Open Select'))

    expect(view.getByRole('listbox')).toHaveAccessibleName('Select…')
  })
})
