// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'

import { i18n } from '#shared/i18n.ts'

import CommonSelect, { type Props } from '../CommonSelect.vue'

import type { Ref } from 'vue'

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
    props: {
      isTargetVisible: true,
      ...props,
    },
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

  it('can use select all action with active multiple', async () => {
    const modelValue = ref()
    const view = renderSelect({ options, multiple: true }, modelValue)

    await view.events.click(view.getByText('Open Select'))
    await view.events.click(view.getByText('select all options'))

    expect(modelValue.value).toEqual([0, 1, 2])

    expect(view.queryAllByIconName('check-square')).toHaveLength(3)
  })

  it('can add additional actions', async () => {
    const modelValue = ref()

    const actionCallbackSpy = vi.fn()
    const view = renderSelect(
      {
        options,
        multiple: true,
        actions: [
          {
            label: 'example action',
            key: 'example',
            onClick: actionCallbackSpy,
          },
        ],
      },
      modelValue,
    )

    await view.events.click(view.getByText('Open Select'))
    await view.events.click(view.getByText('example action'))

    expect(actionCallbackSpy).toHaveBeenCalledTimes(1)
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

  it('forces translation if placeholder is provided', async () => {
    const options = [
      {
        value: 0,
        label: 'Label (%s)',
        labelPlaceholder: ['A'],
        heading: 'Heading (%s)',
        headingPlaceholder: ['B'],
      },
    ]

    const view = renderSelect({ options, noOptionsLabelTranslation: true })

    await view.events.click(view.getByText('Open Select'))
    expect(
      view.getByRole('option', { name: 'Label (A) – Heading (B)' }),
    ).toBeInTheDocument()
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

  it('supports optional headings', async () => {
    const view = renderSelect({
      options: [
        {
          value: 0,
          label: 'foo (%s)',
          labelPlaceholder: ['1'],
          heading: 'bar (%s)',
          headingPlaceholder: ['2'],
        },
      ],
    })

    await view.events.click(view.getByText('Open Select'))

    const option = view.getByRole('option')

    expect(option).toHaveTextContent('foo (1) – bar (2)')
    expect(option.children[1]).toHaveAttribute(
      'aria-label',
      'foo (1) – bar (2)',
    )
  })

  it('supports navigating options with children', async () => {
    const testChildOption = {
      value: 1,
      label: 'child',
    }

    const testParentOption = {
      value: 1,
      label: 'parent',
      disabled: true,
      children: [testChildOption],
    }

    const view = renderSelect({
      options: [testParentOption],
    })

    await view.events.click(view.getByText('Open Select'))

    expect(
      view.queryByRole('button', { name: 'Back to previous page' }),
    ).not.toBeInTheDocument()

    expect(view.getByRole('option')).toHaveTextContent('parent')
    expect(view.getByRole('option')).toHaveAttribute('aria-disabled', 'true')

    await view.events.click(view.getByRole('button', { name: 'Has submenu' }))

    expect(view.emitted().push).toEqual([[testParentOption]])

    await view.rerender({
      options: [testChildOption],
      isChildPage: true,
    })

    expect(view.getByRole('option')).toHaveTextContent('child')

    await view.events.click(
      view.getByRole('button', { name: 'Back to previous page' }),
    )

    expect(view.emitted().pop).toEqual([[]])

    await view.rerender({
      options: [testParentOption],
      isChildPage: false,
    })

    expect(
      view.queryByRole('button', { name: 'Back to previous page' }),
    ).not.toBeInTheDocument()

    expect(view.getByRole('option')).toHaveTextContent('parent')
    expect(view.getByRole('option')).toHaveAttribute('aria-disabled', 'true')

    await view.events.click(view.getByRole('button', { name: 'Has submenu' }))

    await view.rerender({
      options: [testChildOption],
      isChildPage: true,
    })

    await view.events.click(view.getByText('child'))

    expect(view.emitted().select).toEqual([[testChildOption]])
  })
})
