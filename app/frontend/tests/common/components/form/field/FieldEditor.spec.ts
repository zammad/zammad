// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import FieldEditorInner from '@common/components/form/field/FieldEditor/FieldEditorInner.vue'
import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'
import { getVMFromWrapper, getWrapper } from '@tests/support/components'
import { waitForTimeout } from '@tests/support/utils'
import { VueWrapper } from '@vue/test-utils'
import { ComponentPublicInstance, nextTick } from 'vue'

const wrapperParameters = {
  form: true,
  formField: true,
}

const wrapper = getWrapper(FormKit, {
  ...wrapperParameters,
  props: {
    name: 'editor',
    type: 'editor',
    id: 'editor',
  },
})

describe('Form - Field - Editor (TipTap)', () => {
  it('mounts successfully', () => {
    expect(wrapper.exists()).toBe(true)
  })

  it('can render a editor', () => {
    expect(wrapper.html()).toContain('formkit-outer')
    expect(wrapper.html()).toContain('formkit-wrapper')
    expect(wrapper.html()).toContain('formkit-inner')
    expect(wrapper.find('div#editor')).toBeTruthy()
    expect(
      wrapper.find('div.ProseMirror').attributes().contenteditable,
    ).toBeDefined()
    expect(wrapper.find('label').exists()).toBe(false)

    const node = getNode('editor')
    expect(node?.value).toBe(undefined)
  })

  it('set some props', async () => {
    expect.assertions(2)

    wrapper.setProps({
      label: 'Body',
      help: 'This is the help text',
      // placeholder: 'Enter your body',
    })

    await nextTick()

    expect(wrapper.find('label').text()).toBe('Body')
    expect(wrapper.find('.formkit-help').text()).toBe('This is the help text')

    // const attributes = wrapper.find('textarea').attributes()
    // expect(attributes.placeholder).toBe('Enter your body')
  })

  it('check for the input event', async () => {
    expect.assertions(2)

    // We need to set the new content with the editor object, because contenteditable is currently
    // not supported in JSDom.
    const innerEditorWrapper = wrapper.getComponent(
      FieldEditorInner,
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
    ) as VueWrapper<ComponentPublicInstance<any>>

    getVMFromWrapper(innerEditorWrapper).editor.commands.setContent(
      '<p>Example body.</p>',
      true,
    )

    await waitForTimeout()

    expect(wrapper.emitted('input')).toBeTruthy()

    const emittedInput = wrapper.emitted().input as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toBe('<p>Example body.</p>')
  })
})
