// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import Form from '@shared/components/Form/Form.vue'
import UserError from '@shared/errors/UserError'
import type { FormValues } from '@shared/components/Form'
import type { FormKitNode } from '@formkit/core'
import { within } from '@testing-library/vue'
import type { ExtendedRenderResult } from '@tests/support/components'
import { renderComponent } from '@tests/support/components'
import { waitForNextTick } from '@tests/support/utils'
import { nextTick, onMounted, ref } from 'vue'

const wrapperParameters = {
  form: true,
  attachTo: document.body,
}

describe('Form.vue', () => {
  let wrapper: ExtendedRenderResult

  beforeAll(() => {
    wrapper = renderComponent(Form, {
      ...wrapperParameters,
      props: {
        schema: [
          {
            type: 'text',
            name: 'title',
            label: 'Text',
          },
          {
            type: 'textarea',
            name: 'text',
            label: 'Textarea',
            value: 'Some text',
          },
        ],
      },
      unmount: false,
    })
  })

  afterAll(() => {
    wrapper.unmount()
  })

  it('set a schema with fields', () => {
    expect(wrapper.html()).toContain('form')

    const text = wrapper.getByLabelText('Text')
    expect(text).toBeInTheDocument()
    // wrapped in a div with data-type
    expect(text.closest('div[data-type="text"]')).toBeInTheDocument()

    const textarea = wrapper.getByLabelText('Textarea')
    expect(textarea).toBeInTheDocument()
    // wrapped in a div with data-type
    expect(textarea.closest('div[data-type="textarea"]')).toBeInTheDocument()
  })

  it('check for current initial field values', () => {
    const textarea = wrapper.getByLabelText('Textarea')

    expect(textarea).toHaveDisplayValue('Some text')
  })

  it('check for changed field values', async () => {
    const text = wrapper.getByLabelText('Text')

    await wrapper.events.type(text, 'Example title')

    expect(text).toHaveDisplayValue('Example title')
  })

  it('implements submit event/handler', async () => {
    const submitCallbackSpy = vi.fn()

    await wrapper.rerender({
      onSubmit: (data: FormValues) => submitCallbackSpy(data),
    })

    await wrapper.events.type(wrapper.getByLabelText('Text'), '{Enter}')

    expect(wrapper.emitted().submit).toBeTruthy()

    expect(submitCallbackSpy).toHaveBeenCalledWith({
      title: 'Example title',
      text: 'Some text',
      formId: expect.any(String),
    })
  })

  it('handles promise error messages in submit event/handler', async () => {
    await wrapper.rerender({
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

    await wrapper.events.type(wrapper.getByLabelText('Text'), '{Enter}')

    await waitForNextTick(true)

    const error = wrapper.getByText('Title should be different.')

    expect(error).toBeInTheDocument()
    // we depend on this attributes, so we test it
    expect(error).toHaveAttribute('data-message-type', 'error')
    expect(error.closest('[data-errors="true"]')).toBeInTheDocument()
  })

  it('implements changed event', async () => {
    const text = wrapper.getByLabelText('Text')

    await wrapper.events.clear(text)
    await wrapper.events.type(text, 'Other title')

    const emittedChange = wrapper.emitted().changed as Array<Array<string>>

    expect(emittedChange[emittedChange.length - 1]).toStrictEqual([
      'Other title',
      'title',
    ])
  })

  it('can change field information - hide title field', async () => {
    await wrapper.rerender({
      changeFields: {
        title: {
          show: false,
        },
      },
    })

    await nextTick()

    expect(wrapper.queryByLabelText('Text')).not.toBeInTheDocument()
  })

  it('can change field information - show title again and change values', async () => {
    await wrapper.rerender({
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

    const input = wrapper.getByLabelText('Text')
    expect(input).toHaveDisplayValue('Changed title')

    const textarea = wrapper.getByLabelText('Textarea')
    expect(textarea).toHaveDisplayValue('A other text.')
  })
})

describe('Form.vue - Edge Cases', () => {
  it('can use initial values', () => {
    const wrapper = renderComponent(Form, {
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

    const input = wrapper.getByLabelText('Title')
    expect(input).toHaveDisplayValue('Initial title')
  })

  it('can use form layout in schema', () => {
    const wrapper = renderComponent(Form, {
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

    const fieldset = wrapper.getByRole('group')

    // children are inside a form
    expect(fieldset.closest('form')).toBeInTheDocument()

    const group = within(fieldset)

    expect(group.getByLabelText('Title')).toBeInTheDocument()
    expect(group.getByLabelText('Text')).toBeInTheDocument()
  })

  it('can use DOM elements and other components inside of the schema', () => {
    const wrapper = renderComponent(Form, {
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
                  external: true,
                  link: 'https://example.com',
                },
                children: 'Example Link',
              },
            ],
          },
        ],
      },
    })

    expect(
      wrapper.container.querySelector('div.example-class'),
    ).toBeInTheDocument()

    expect(wrapper.getByText('Example Link')).toBeInTheDocument()
    expect(wrapper.getByLabelText('Title')).toBeInTheDocument()
  })

  it('can use list/group fields in form schema', () => {
    const wrapper = renderComponent(Form, {
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

    const group = wrapper.getByRole('form')
    const view = within(group)

    expect(view.getByLabelText('Street')).toBeInTheDocument()
    expect(view.getByLabelText('City')).toBeInTheDocument()
  })

  // TODO: add test case for loading animation, when real query call is availabe (can then be mocked).

  it('can use fields slot instead of a form schema', () => {
    const wrapper = renderComponent(Form, {
      ...wrapperParameters,
      slots: {
        default: '<FormKit type="text" name="example" label="Example" />',
      },
    })

    expect(wrapper.getByRole('form')).toBeInTheDocument()

    const input = wrapper.getByLabelText('Example')

    expect(input).toBeInTheDocument()
  })

  it('exposes the form node', () => {
    expect.assertions(2)

    return new Promise<void>((resolve) => {
      renderComponent(
        {
          template: `<div><Form ref="form" :schema="schema" /></div>`,
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

            const form = ref<{ formNode: FormKitNode }>()

            onMounted(() => {
              expect(form.value).toBeDefined()
              expect(form.value?.formNode.props.type).toBe('form')

              resolve()
            })

            return { schema, form }
          },
        } as any,
        {
          form: true,
        },
      )
    })
  })
})

describe('Form.vue - Empty', () => {
  it('check for no form output without a schema with fields', () => {
    const wrapper = renderComponent(Form, {
      ...wrapperParameters,
      props: {},
    })
    expect(wrapper.html()).not.toContain('form')
  })
})
