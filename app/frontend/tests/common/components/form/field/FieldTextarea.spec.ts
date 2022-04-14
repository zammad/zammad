// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { i18n } from '@common/utils/i18n'
import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'
import { ExtendedRenderResult, getWrapper } from '@tests/support/components'
import { waitForTimeout } from '@tests/support/utils'
import { nextTick } from 'vue'

const wrapperParameters = {
  form: true,
  formField: true,
}

describe('Form - Field - Textarea (Formkit-BuildIn)', () => {
  let wrapper: ExtendedRenderResult

  beforeAll(() => {
    wrapper = getWrapper(FormKit, {
      ...wrapperParameters,
      props: {
        name: 'textarea',
        type: 'textarea',
        id: 'textarea',
        label: 'Body',
      },
      unmount: false,
    })
  })

  afterAll(() => {
    wrapper.unmount()
  })

  it('can render a textarea', () => {
    const textarea = wrapper.getByLabelText('Body')

    expect(textarea).toHaveAttribute('id', 'textarea')
    expect(textarea).not.toHaveAttribute('placeholder')

    const node = getNode('textarea')
    expect(node?.value).toBe(undefined)
  })

  it('set some props', async () => {
    await wrapper.rerender({
      help: 'This is the help text',
      placeholder: 'Enter your body',
      cols: 10,
      maxlength: 100,
      minlength: 10,
      rows: 5,
    })

    expect(wrapper.getByText('This is the help text')).toBeInTheDocument()

    const textarea = wrapper.getByLabelText('Body')

    expect(textarea).toHaveAttribute('placeholder', 'Enter your body')
    expect(textarea).toHaveAttribute('cols', '10')
    expect(textarea).toHaveAttribute('rows', '5')
    expect(textarea).toHaveAttribute('maxlength', '100')
    expect(textarea).toHaveAttribute('minlength', '10')
  })

  it('check for the input event', async () => {
    const textarea = wrapper.getByLabelText('Body')

    await wrapper.events.type(textarea, 'example body')

    await waitForTimeout()

    const emittedInput = wrapper.emitted().input as Array<Array<InputEvent>>

    expect(emittedInput[11][0]).toBe('example body')
  })

  it('can be disabled', async () => {
    const textarea = wrapper.getByLabelText('Body')

    expect(textarea).toBeEnabled()

    await wrapper.rerender({
      disabled: true,
    })

    expect(textarea).toBeDisabled()

    // Rest the disabled state again and check if it's enabled again.
    await wrapper.rerender({
      disabled: false,
    })

    expect(textarea).toBeEnabled()
  })
})

describe('Form - Field - Textarea (Formkit-BuildIn) - Translations', () => {
  it('can translate placeholder attribute', async () => {
    const wrapper = getWrapper(FormKit, {
      ...wrapperParameters,
      props: {
        label: 'Body',
        help: 'This is the help text',
        placeholder: 'Enter your body',
        name: 'textarea',
        type: 'textarea',
        id: 'textarea',
      },
    })

    const textarea = wrapper.getByLabelText('Body')

    expect(textarea).toHaveAttribute('placeholder', 'Enter your body')

    const map = new Map([['Enter your body', 'Gib deinen Text ein']])

    i18n.setTranslationMap(map)

    await nextTick()

    expect(textarea).toHaveAttribute('placeholder', 'Gib deinen Text ein')
  })

  it('can translate label with label placeholder', () => {
    const wrapper = getWrapper(FormKit, {
      ...wrapperParameters,
      props: {
        label: 'Body %s %s',
        labelPlaceholder: ['Example', 'Placeholder'],
        name: 'textarea',
        type: 'textarea',
        id: 'textarea',
      },
    })

    expect(
      wrapper.getByLabelText('Body Example Placeholder'),
    ).toBeInTheDocument()
  })
})
