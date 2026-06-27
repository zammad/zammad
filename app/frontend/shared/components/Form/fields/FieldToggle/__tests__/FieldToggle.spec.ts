// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'
import { flushPromises } from '@vue/test-utils'
import { ref } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

const renderToggle = (props: any = {}) => {
  return renderComponent(FormKit, {
    form: true,
    props: {
      name: 'toggle',
      type: 'toggle',
      id: 'toggle',
      label: 'Toggle',
      variants: {
        true: 'yes',
        false: 'no',
      },
      ...props,
    },
  })
}

describe('FieldToggle', () => {
  test('can change toggle value', async () => {
    const view = renderToggle()

    const switcher = view.getByLabelText('Toggle')

    expect(switcher).not.toBeChecked()

    await view.events.click(switcher)

    expect(switcher).toBeChecked()
  })

  test("can't change disabled value", async () => {
    const view = renderToggle({ disabled: true })

    const switcher = view.getByLabelText('Toggle')

    expect(switcher).not.toBeChecked()

    await view.events.click(switcher)

    expect(switcher).not.toBeChecked()
  })

  test("can't change value, if its not in variants", async () => {
    const view = renderToggle({ value: false, variants: { false: 'no' } })

    const switcher = view.getByLabelText('Toggle')

    expect(switcher).not.toBeChecked()

    await view.events.click(switcher)

    expect(switcher).not.toBeChecked()
  })

  test('resets value to opposite, if variant removes the current one', async () => {
    const toggle = renderToggle({ value: true })
    const switcher = toggle.getByLabelText('Toggle')

    expect(switcher).toBeChecked()

    await toggle.rerender({
      variants: {
        false: 'no',
      },
    })

    expect(switcher).not.toBeChecked()
    expect(switcher).toBeDisabled()
  })

  test('doesnt reset current value, if variants change, but still have the value', async () => {
    const toggle = renderToggle({ value: true })
    const switcher = toggle.getByLabelText('Toggle')

    expect(switcher).toBeChecked()

    await toggle.rerender({
      variants: {
        true: 'no',
      },
    })

    expect(switcher).toBeChecked()
    expect(switcher).toBeDisabled()
  })

  test('resets to undefined, if neither variants are available', async () => {
    const toggle = renderToggle({ value: true, variants: {} })
    await flushPromises()

    const node = getNode('toggle')
    expect(node).toHaveProperty('_value', undefined)

    expect(toggle.getByLabelText('Toggle')).not.toBeChecked()
  })

  test('renders the current variant label inline and updates it on toggle', async () => {
    const view = renderToggle({ value: false, inlineLabel: true })

    expect(view.getByText('no')).toBeInTheDocument()

    await view.events.click(view.getByLabelText('Toggle'))

    expect(view.getByText('yes')).toBeInTheDocument()
  })

  test('describes the switch with the current state label for screen readers', async () => {
    const view = renderToggle({ value: false, inlineLabel: true })
    const switcher = view.getByLabelText('Toggle')

    // The switch's accessible name stays the field label; the current variant is exposed as a
    //  description so screen readers announce what the on/off state means.
    expect(switcher.getAttribute('aria-describedby')?.split(' ')).toContain(view.getByText('no').id)

    await view.events.click(switcher)

    expect(switcher.getAttribute('aria-describedby')?.split(' ')).toContain(
      view.getByText('yes').id,
    )
  })

  test('renders an icon inside the knob per state', async () => {
    const view = renderToggle({
      value: false,
      icons: { true: 'lock', false: 'unlock' },
    })

    expect(view.getByIconName('unlock')).toBeInTheDocument()

    await view.events.click(view.getByLabelText('Toggle'))

    expect(view.getByIconName('lock')).toBeInTheDocument()
  })

  test('invertVisual flips only the visual on-state, not the value', async () => {
    const view = renderToggle({ value: true, invertVisual: true })
    const switcher = view.getByLabelText('Toggle')
    const knob = switcher.firstElementChild as HTMLElement

    // The value (and thus aria-checked) still reflects `true`...
    expect(switcher).toBeChecked()
    // ...but the knob visually rests in the OFF (left) position because `invertVisual` is set.
    expect(knob.className).toContain('translate-x-px')

    await view.events.click(switcher)

    // Toggling to `false` keeps aria-checked in sync with the value and slides the knob ON.
    expect(switcher).not.toBeChecked()
    expect(knob.className).toContain('translate-x-[17px]')
  })

  test('can use model-value to toggle', async () => {
    const toggled = ref(false)

    // Currently only "modelValue" is working: https://github.com/formkit/formkit/issues/629
    const view = renderComponent(
      {
        template: `<div><FormKit label="Toggle" type="toggle" name="toggle" id="toggle" :variants="variants" :modelValue="toggled" /></div>`,
        components: {
          FormKit,
        },
        setup() {
          const variants = {
            true: 'yes',
            false: 'no',
          }
          return { toggled, variants }
        },
      },
      {
        form: true,
      },
    )

    const switcher = view.getByLabelText('Toggle')

    expect(switcher).not.toBeChecked()

    toggled.value = true

    await waitForNextTick()

    expect(switcher).toBeChecked()
  })
})
