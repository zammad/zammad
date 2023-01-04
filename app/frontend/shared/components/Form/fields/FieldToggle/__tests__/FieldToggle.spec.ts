// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'
import { renderComponent } from '@tests/support/components'
import { flushPromises } from '@vue/test-utils'

const renderToggle = (props: any = {}) => {
  return renderComponent(FormKit, {
    form: true,
    formField: true,
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
})
