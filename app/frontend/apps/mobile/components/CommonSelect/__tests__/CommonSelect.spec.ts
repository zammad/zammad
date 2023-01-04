// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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

beforeEach(() => {
  i18n.setTranslationMap(new Map([]))
})

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
      // TODO should work just with view.getByIconName('mobile-check') with Vitest 0.19
      view.getByIconName((name, node) => {
        return (
          name === '#icon-mobile-check' &&
          !node?.parentElement?.classList.contains('invisible')
        )
      }),
    ).toBeInTheDocument()
    await view.events.click(view.getByText('Item A'))

    expect(view.emitted().select).toEqual([[options[0]], [options[0]]])
    expect(modelValue.value).toBe(undefined)
  })

  test("doesn't close select with noClose props", async () => {
    const view = renderSelect({ options, noClose: true })

    await view.events.click(view.getByText('Open Select'))
    await view.events.click(view.getByRole('option', { name: 'Item A' }))

    expect(view.getByRole('dialog')).toBeInTheDocument()
  })

  test('can select and deselect multiple values', async () => {
    const modelValue = ref()
    const view = renderSelect({ options, multiple: true }, modelValue)

    await view.events.click(view.getByText('Open Select'))
    await view.events.click(view.getByText('Item A'))

    expect(modelValue.value).toEqual([0])

    expect(view.queryAllByIconName('mobile-check-box-yes')).toHaveLength(1)
    await view.events.click(view.getByText('Item A'))

    expect(modelValue.value).toEqual([])

    await view.events.click(view.getByText('Item A'))
    await view.events.click(view.getByText('Item B'))

    expect(modelValue.value).toEqual([0, 1])

    expect(view.queryAllByIconName('mobile-check-box-yes')).toHaveLength(2)
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

  test('can use boolean as value', async () => {
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

  test('has an accessible name', async () => {
    const view = renderSelect({ options })

    await view.events.click(view.getByText('Open Select'))

    expect(view.getByRole('dialog')).toHaveAccessibleName(
      'Dialog window with selections',
    )
  })
})

describe('traversing and focusing select', () => {
  it('focuses on the first element, when no option is selected', async () => {
    const view = renderSelect({ options })

    await view.events.click(view.getByText('Open Select'))
    expect(view.getByRole('option', { name: 'Item A' })).toHaveFocus()
  })

  it('focuses selected element, when option is selected', async () => {
    const modelValue = ref(1)
    const view = renderSelect({ options }, modelValue)

    await view.events.click(view.getByText('Open Select'))
    expect(view.getByRole('option', { name: 'Item B' })).toHaveFocus()
  })

  it('emits close when closing, so children can refocus select', async () => {
    const view = renderSelect({ options })

    await view.events.click(view.getByText('Open Select'))
    await view.events.click(view.getByRole('option', { name: 'Item A' }))

    expect(view.emitted().close).toBeDefined()
  })

  it('can travers with keyboard and select with a space', async () => {
    const modelValue = ref()
    const view = renderSelect({ options }, modelValue)

    await view.events.click(view.getByText('Open Select'))

    const optionsElements = view.getAllByRole('option')
    expect(optionsElements).toHaveLength(3)

    const [itemI, itemII, itemIII] = optionsElements

    expect(itemI).toHaveFocus()

    await view.events.keyboard('{ArrowDown}')

    expect(itemII).toHaveFocus()

    await view.events.keyboard('{ArrowDown}')

    expect(itemIII).toHaveFocus()

    await view.events.keyboard('{ArrowDown}')

    expect(itemI).toHaveFocus()

    await view.events.keyboard('{ArrowUp}')

    expect(itemIII).toHaveFocus()

    await view.events.keyboard('{ArrowUp}')

    expect(itemII).toHaveFocus()

    await view.events.keyboard(' ')

    expect(modelValue.value).toBe(1)
  })

  it('locks tab inside select', async () => {
    const modelValue = ref()
    const view = renderSelect({ options }, modelValue)

    await view.events.click(view.getByText('Open Select'))

    const optionsElements = view.getAllByRole('option')
    const [itemI, itemII, itemIII] = optionsElements

    expect(itemI).toHaveFocus()

    await view.events.keyboard('{Tab}')

    expect(itemII).toHaveFocus()

    await view.events.keyboard('{Tab}')

    expect(itemIII).toHaveFocus()

    await view.events.keyboard('{Tab}')

    expect(itemI).toHaveFocus()
  })

  it('refocuses on the last element that opened select', async () => {
    const view = renderSelect({ options })

    await view.events.click(view.getByText('Open Select'))
    await view.events.keyboard('{Escape}')

    expect(view.getByText('Open Select')).toHaveFocus()
  })

  it("doesn't refocuses on the last element that opened select, when specified", async () => {
    const view = renderSelect({ options, noRefocus: true })

    await view.events.click(view.getByText('Open Select'))
    await view.events.keyboard('{Escape}')

    expect(view.getByText('Open Select')).not.toHaveFocus()
  })

  it('focuses by filtered words', async () => {
    const view = renderSelect({ options })
    await view.events.click(view.getByText('Open Select'))

    expect(view.getByRole('option', { name: 'Item A' })).toHaveFocus()

    await view.events.debounced(() => view.events.keyboard('Item C'))

    expect(view.getByRole('option', { name: 'Item C' })).toHaveFocus()
  })
})
