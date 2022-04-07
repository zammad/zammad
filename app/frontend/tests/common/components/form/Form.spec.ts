// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import Form from '@common/components/form/Form.vue'
import UserError from '@common/errors/UserError'
import { FormValues } from '@common/types/form'
import { FormKitNode, getNode } from '@formkit/core'
import { getVMFromWrapper, getWrapper } from '@tests/support/components'
import { waitForTimeout, waitForNextTick } from '@tests/support/utils'
import { nextTick } from 'vue'

const wrapperParameters = {
  form: true,
  attachTo: document.body,
}

let wrapper = getWrapper(Form, {
  ...wrapperParameters,
  props: {},
})

describe('Form.vue', () => {
  it('mounts successfully', () => {
    expect(wrapper.exists()).toBe(true)
  })

  it('check for no form output without a schema with fields', () => {
    expect(wrapper.html()).not.toContain('form')
  })

  it('set a schema with fields', () => {
    wrapper = getWrapper(Form, {
      ...wrapperParameters,
      props: {
        schema: [
          {
            type: 'text',
            name: 'title',
            label: 'Title',
          },
          {
            type: 'textarea',
            name: 'text',
            label: 'Text',
            value: 'Some text',
          },
        ],
      },
    })

    expect(wrapper.html()).toContain('form')

    // Check for some field ouput.
    expect(wrapper.html()).toContain('<input')
    expect(wrapper.find('div[data-type="text"] label').text()).toContain(
      'Title',
    )
    expect(wrapper.html()).toContain('<textarea')
    expect(wrapper.find('div[data-type="textarea"] label').text()).toContain(
      'Text',
    )
  })

  it('check for current initial field values', () => {
    expect(getVMFromWrapper(wrapper).values).toStrictEqual({
      title: undefined,
      text: 'Some text',
    })
  })

  it('check for changed field values', async () => {
    expect.assertions(1)

    const input = wrapper.find('input')
    input.setValue('Example title')
    input.trigger('input')

    await waitForTimeout()

    expect(getVMFromWrapper(wrapper).values).toStrictEqual({
      title: 'Example title',
      text: 'Some text',
    })
  })

  it('implements submit event/handler', async () => {
    expect.assertions(2)

    const submitCallbackSpy = vi.fn()

    wrapper.setProps({
      onSubmit: (data: FormValues) => submitCallbackSpy(data),
    })

    const { formId } = getVMFromWrapper(wrapper)

    const formNode = getNode(formId) as FormKitNode
    formNode.submit()

    await nextTick()

    expect(wrapper.emitted('submit')).toBeTruthy()

    expect(submitCallbackSpy).toHaveBeenCalledWith({
      title: 'Example title',
      text: 'Some text',
      formId,
    })
  })

  it('handles promise error messages in submit event/handler', async () => {
    expect.assertions(2)

    wrapper.setProps({
      onSubmit: (): Promise<void> => {
        return new Promise((resolve, reject) => {
          const userErrors = new UserError([
            {
              field: 'title',
              message: 'Title should be different.',
            },
          ])
          reject(userErrors)
        })
      },
    })

    const { formId } = getVMFromWrapper(wrapper)

    const formNode = getNode(formId) as FormKitNode
    formNode.submit()

    await waitForNextTick(true)

    expect(wrapper.find('[data-errors="true"]')).toBeTruthy()
    expect(wrapper.find('[data-message-type="error"]').text()).toBe(
      'Title should be different.',
    )
  })

  it('implements changed event', async () => {
    expect.assertions(2)

    const input = wrapper.find('input')
    input.setValue('Other title')
    input.trigger('input')

    expect(wrapper.emitted('changed')).toBeTruthy()

    const emittedChange = wrapper.emitted().changed as Array<Array<string>>

    expect(emittedChange[1]).toStrictEqual(['Other title', 'title'])
  })

  it('can change field information - hide title field', async () => {
    expect.assertions(1)

    wrapper.setProps({
      changeFields: {
        title: {
          show: false,
        },
      },
    })

    await nextTick()

    expect(wrapper.html()).not.toContain('<input')
  })

  it('can change field information - show title again and change values', async () => {
    expect.assertions(2)

    wrapper.setProps({
      changeFields: {
        title: {
          show: true,
          value: 'Changed title',
        },
        text: {
          value: 'A other text.',
        },
      },
    })

    await waitForNextTick(true)

    const input = wrapper.find('input')
    expect(input.element.value).toBe('Changed title')

    const textarea = wrapper.find('textarea')
    expect(textarea.element.value).toBe('A other text.')
  })

  it('can use initial values', () => {
    wrapper = getWrapper(Form, {
      ...wrapperParameters,
      props: {
        schema: [
          {
            type: 'text',
            name: 'title',
            label: 'Title',
          },
          {
            type: 'textarea',
            name: 'text',
            label: 'Text',
          },
        ],
        initialValues: {
          title: 'Initial title',
        },
      },
    })

    const input = wrapper.find('input')
    expect(input.element.value).toBe('Initial title')
  })

  it('can use form layout in schema', () => {
    wrapper = getWrapper(Form, {
      ...wrapperParameters,
      props: {
        schema: [
          {
            isLayout: true,
            component: 'FormLayout',
            props: {
              columns: 2,
            },
            children: [
              {
                type: 'text',
                name: 'title',
                label: 'Title',
              },
              {
                type: 'textarea',
                name: 'text',
                label: 'Text',
              },
            ],
          },
        ],
      },
    })

    expect(wrapper.html()).toContain('<form')
    expect(wrapper.html()).toContain('<fieldset')
    expect(wrapper.html()).toContain('<input')
    expect(wrapper.html()).toContain('<textarea')
  })

  it('can use DOM elements and other components inside of the schema', () => {
    wrapper = getWrapper(Form, {
      ...wrapperParameters,
      router: true,
      props: {
        schema: [
          {
            isLayout: true,
            element: 'div',
            attrs: {
              class: 'example-class',
            },
            children: [
              {
                type: 'text',
                name: 'title',
                label: 'Title',
              },
              {
                isLayout: true,
                component: 'CommonLink',
                props: {
                  isExternalLink: true,
                  link: 'https://example.com',
                },
                children: 'Example Link',
              },
            ],
          },
        ],
      },
    })

    expect(wrapper.html()).toContain('form')
    expect(wrapper.html()).toContain('<input')
    expect(wrapper.find('div.example-class')).toBeTruthy()
    expect(wrapper.find('a').text()).toBe('Example Link')
  })

  it('can use list/group fields in form schema', () => {
    wrapper = getWrapper(Form, {
      ...wrapperParameters,
      props: {
        schema: [
          {
            type: 'group',
            name: 'adress',
            children: [
              {
                type: 'text',
                name: 'street',
                label: 'Street',
              },
              {
                type: 'text',
                name: 'city',
                label: 'City',
              },
            ],
          },
        ],
      },
    })

    expect(wrapper.html()).toContain('form')
    expect(wrapper.html()).toContain('Street')
    expect(wrapper.html()).toContain('City')
  })

  // TODO: add test case for loading animation, when real query call is availabe (can then be mocked).

  it('can use fields slot instead of a form schema', () => {
    wrapper = getWrapper(Form, {
      ...wrapperParameters,
      slots: {
        fields: '<FormKit type="text" name="example" label="Example" />',
      },
    })

    expect(wrapper.html()).toContain('form')

    // Check for some field ouput.
    expect(wrapper.html()).toContain('<input')
    expect(wrapper.find('div[data-type="text"] label').text()).toContain(
      'Example',
    )
  })

  it('exposes the form node', () => {
    wrapper = getWrapper(
      {
        template: `<div><Form ref="form" v-bind:schema="schema" /></div>`,
        components: {
          Form,
        },
        setup() {
          const schema = [
            {
              type: 'text',
              name: 'title',
              label: 'Title',
            },
            {
              type: 'textarea',
              name: 'text',
              label: 'Text',
              value: 'Some text',
            },
          ]

          return { schema }
        },
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
      } as any,
      {
        form: true,
      },
    )

    const formNode = getVMFromWrapper(wrapper).$refs.form
      .formNode as FormKitNode
    expect(formNode.props.type).toBe('form')
  })
})
