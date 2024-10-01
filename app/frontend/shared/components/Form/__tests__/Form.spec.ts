// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { waitFor, within } from '@testing-library/vue'
import { nextTick, onMounted, ref } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'
import type {
  ExtendedMountingOptions,
  ExtendedRenderResult,
} from '#tests/support/components/index.ts'
import { mockGraphQLApi } from '#tests/support/mock-graphql-api.ts'
import { waitForNextTick, waitUntil } from '#tests/support/utils.ts'

import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import Form from '#shared/components/Form/Form.vue'
import type { Props } from '#shared/components/Form/Form.vue'
import { ObjectManagerFrontendAttributesDocument } from '#shared/entities/object-attributes/graphql/queries/objectManagerFrontendAttributes.api.ts'
import frontendObjectAttributes from '#shared/entities/ticket/__tests__/mocks/frontendObjectAttributes.json'
import UserError from '#shared/errors/UserError.ts'
import {
  EnumFormUpdaterId,
  EnumObjectManagerObjects,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import type { FormUpdaterAdditionalParams } from '#shared/types/form.ts'

import { FormUpdaterDocument } from '../graphql/queries/formUpdater.api.ts'
import {
  type FormRef,
  type FormValues,
  type FormSchemaField,
  FormHandlerExecution,
} from '../types.ts'

import type { FormKitNode } from '@formkit/core'
import type { Ref } from 'vue'

const wrapperParameters = {
  form: true,
  attachTo: document.body,
  router: true,
}

const renderForm = async (options: ExtendedMountingOptions<Props> = {}) => {
  const wrapper = renderComponent(Form, {
    ...wrapperParameters,
    ...options,
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
          label: 'Textarea',
          value: 'Some text',
        },
      ],
      ...(options.props || {}),
    },
  })

  await waitUntil(() => wrapper.emitted().settled)

  return wrapper
}

const renderTicketCreateForm = async ({
  formUpdaterId,
  onSubmit,
  clearValuesAfterSubmit,
  formUpdaterAdditionalParams,
}: {
  formUpdaterId?: EnumFormUpdaterId
  onSubmit?: () => unknown
  clearValuesAfterSubmit?: boolean
  formUpdaterAdditionalParams?: FormUpdaterAdditionalParams
} = {}) => {
  return new Promise<{
    view: ExtendedRenderResult
    form: Ref<FormRef>
  }>((resolve) => {
    const view = renderComponent(
      {
        template: `<div><Form ref="form" id="form-ticket-create" :schema="schema" :form-updater-id="formUpdaterId" :form-updater-additional-params="formUpdaterAdditionalParams" :clear-values-after-submit="clearValuesAfterSubmit" @submit="onSubmit" /></div>`,
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
              label: 'Textarea',
              value: 'Some text',
            },
            {
              type: 'submit',
              name: 'submit',
              label: 'Submit',
            },
            {
              type: 'group',
              name: 'group',
              isGroupOrList: true,
              children: [
                {
                  type: 'text',
                  name: 'example',
                  label: 'Example',
                  value: 'Some example',
                },
              ],
            },
          ]
          const form = ref<FormRef>()
          onMounted(() => {
            nextTick(() => {
              resolve({ view, form: form as Ref<FormRef> })
            })
          })
          return {
            schema,
            form,
            formUpdaterId,
            formUpdaterAdditionalParams,
            clearValuesAfterSubmit,
            onSubmit,
          }
        },
      } as any,
      {
        form: true,
      },
    )
  })
}

describe('Form.vue', () => {
  it('set a schema with fields', async () => {
    const wrapper = await renderForm()

    expect(wrapper.html()).toContain('form')

    const text = wrapper.getByLabelText('Title')
    expect(text).toBeInTheDocument()
    // wrapped in a div with data-type
    expect(text.closest('div[data-type="text"]')).toBeInTheDocument()

    const textarea = wrapper.getByLabelText('Textarea')
    expect(textarea).toBeInTheDocument()
    // wrapped in a div with data-type
    expect(textarea.closest('div[data-type="textarea"]')).toBeInTheDocument()
  })

  it('check for current initial field values', async () => {
    const wrapper = await renderForm()

    const textarea = wrapper.getByLabelText('Textarea')

    expect(textarea).toHaveDisplayValue('Some text')
  })

  it('check for changed field values', async () => {
    const wrapper = await renderForm()

    const text = wrapper.getByLabelText('Title')

    await wrapper.events.type(text, 'Example title')

    expect(text).toHaveDisplayValue('Example title')
  })

  it('implements submit event/handler', async () => {
    const submitCallbackSpy = vi.fn()

    const wrapper = await renderForm({
      props: {
        onSubmit: (data: FormValues) => submitCallbackSpy(data),
      },
    })

    const text = wrapper.getByLabelText('Title')
    await wrapper.events.type(text, 'Example title')
    await wrapper.events.type(text, '{Enter}')

    expect(wrapper.emitted().submit).toBeTruthy()

    expect(submitCallbackSpy).toHaveBeenCalledWith({
      title: 'Example title',
      text: 'Some text',
    })
  })

  it('handles promise error messages in submit event/handler', async () => {
    const wrapper = await renderForm({
      props: {
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
      },
    })

    await wrapper.events.type(wrapper.getByLabelText('Title'), '{Enter}')

    await waitForNextTick(true)

    const error = wrapper.getByText('Title should be different.')

    expect(error).toBeInTheDocument()
    // we depend on this attributes, so we test it
    expect(error).toHaveAttribute('data-message-type', 'error')
    expect(error.closest('[data-errors="true"]')).toBeInTheDocument()
  })

  it('stops submit handler when false is returned', async () => {
    const wrapper = await renderForm({
      props: {
        clearValuesAfterSubmit: true,
        onSubmit: (data: FormValues) => {
          if (data.title === 'Other title') return () => {}

          return false
        },
      },
    })

    const title = wrapper.getByLabelText('Title')
    await wrapper.events.type(title, 'Example title')
    await wrapper.events.type(title, '{Enter}')

    expect(wrapper.emitted().submit).toBeTruthy()

    expect(title).toHaveDisplayValue('Example title')

    // For the other value it should run the complete submit flow,
    // so also the reset of the values.
    await wrapper.events.clear(title)
    await wrapper.events.type(title, 'Other title')
    await wrapper.events.type(title, '{Enter}')

    expect(wrapper.emitted().submit).toBeTruthy()
    expect(title).toHaveDisplayValue('')
  })

  it('use complex submit function return signature for special reset handling', async () => {
    const submitCallbackResetSpy = vi.fn()
    const submitCallbackFinallySpy = vi.fn()

    const wrapper = await renderForm({
      props: {
        clearValuesAfterSubmit: true,
        onSubmit: () => {
          return {
            reset: submitCallbackResetSpy,
            finally: submitCallbackFinallySpy,
          }
        },
      },
    })

    const text = wrapper.getByLabelText('Title')
    await wrapper.events.type(text, 'Example title')
    await wrapper.events.type(text, '{Enter}')

    expect(wrapper.emitted().submit).toBeTruthy()

    expect(submitCallbackResetSpy).toHaveBeenCalledWith(
      {
        title: 'Example title',
        text: 'Some text',
      },
      {
        title: 'Example title',
        text: 'Some text',
      },
    )
    expect(submitCallbackFinallySpy).toHaveBeenCalledTimes(1)
  })

  it('implements changed event', async () => {
    const wrapper = await renderForm()

    const text = wrapper.getByLabelText('Title')

    await wrapper.events.clear(text)
    await wrapper.events.type(text, 'Other title')

    const emittedChange = wrapper.emitted().changed as Array<Array<string>>

    expect(emittedChange[emittedChange.length - 1]).toStrictEqual([
      'title',
      'Other title',
      'Other titl',
    ])
  })

  it('can change field information - hide title field and show again', async () => {
    const wrapper = await renderForm({
      props: {
        changeFields: {
          title: {
            show: false,
          },
        },
      },
    })

    expect(wrapper.queryByLabelText('Title')).not.toBeInTheDocument()

    await wrapper.rerender({
      changeFields: {
        title: {
          show: true,
        },
      },
    })

    expect(wrapper.queryByLabelText('Title')).toBeInTheDocument()
  })

  it('can change field information - show title again and change values', async () => {
    const wrapper = await renderForm()

    await wrapper.rerender({
      changeFields: {
        title: {
          value: 'Changed title',
        },
        text: {
          value: 'A other text.',
        },
      },
    })

    await waitForNextTick()

    const input = wrapper.getByLabelText('Title')
    expect(input).toHaveDisplayValue('Changed title')

    const textarea = wrapper.getByLabelText('Textarea')
    expect(textarea).toHaveDisplayValue('A other text.')
  })

  it('uses a passed over form id', async () => {
    await renderForm({
      props: {
        id: '4711',
      },
    })

    const formNode = getNode('4711')

    await formNode?.settled
    expect(formNode).toBeDefined()
  })
})

describe('Form.vue - Edge Cases', () => {
  it('can use initial values', async () => {
    const wrapper = await renderForm({
      props: {
        schema: [
          {
            type: 'text',
            name: 'title',
            label: 'Title',
          },
          {
            type: 'select',
            name: 'shared',
            label: 'Shared',
            props: {
              options: [
                {
                  label: 'yes',
                  value: true,
                },
                {
                  label: 'no',
                  value: false,
                },
              ],
            },
          },
        ],
        initialValues: {
          title: 'Initial title',
          shared: false,
        },
      },
    })

    expect(wrapper.getByLabelText('Title')).toHaveDisplayValue('Initial title')
    expect(wrapper.getByLabelText('Shared')).toHaveValue('no')
  })

  it('can use initial entity object (and prefill auto complete)', async () => {
    const wrapper = await renderForm({
      props: {
        schema: [
          {
            type: 'text',
            name: 'title',
            label: 'Title',
          },
          {
            type: 'select',
            name: 'shared',
            label: 'Shared',
            props: {
              options: [
                {
                  label: 'yes',
                  value: true,
                },
                {
                  label: 'no',
                  value: false,
                },
              ],
            },
          },
          {
            type: 'select',
            name: 'domain_assignment',
            label: 'Domain Assignment',
            props: {
              options: [
                {
                  label: 'yes',
                  value: true,
                },
                {
                  label: 'no',
                  value: false,
                },
              ],
            },
          },
          {
            type: 'organization',
            name: 'organization_id',
            label: 'Organization',
            props: {
              belongsToObjectField: 'organization',
            },
          },
        ],
        initialEntityObject: {
          title: 'Initial title',
          shared: false,
          domainAssignment: true,
          organization: {
            name: 'Example',
            internalId: '123',
          },
        },
      },
    })

    expect(wrapper.getByLabelText('Title')).toHaveValue('Initial title')
    expect(wrapper.getByLabelText('Shared')).toHaveValue('no')
    expect(wrapper.getByLabelText('Domain Assignment')).toHaveValue('yes')
    expect(wrapper.getByLabelText('Organization')).toHaveTextContent('Example')
  })

  it('adds link attribute for custom fields with linktemplate', async () => {
    const wrapper = await renderForm({
      props: {
        schema: [
          {
            type: 'text',
            name: 'custom_title',
            label: 'Custom Title',
          },
        ],
        initialEntityObject: {
          title: 'Initial title',
          objectAttributeValues: [
            {
              attribute: {
                name: 'custom_title',
                display: 'Custom Title',
                dataType: 'input',
                dataOption: {
                  default: '',
                  type: 'text',
                  linktemplate: 'https://example.com/#{rendered}',
                  null: true,
                },
              },
              value: '',
              renderedLink: 'https://example.com/rendered',
            },
          ],
        },
      },
    })

    expect(wrapper.getByRole('link')).toHaveAttribute(
      'href',
      'https://example.com/rendered',
    )
  })

  it('can use form layout in schema', async () => {
    const wrapper = await renderForm({
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
                label: 'Textarea',
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
    expect(group.getByLabelText('Textarea')).toBeInTheDocument()
  })

  it('can use DOM elements and other components inside of the schema', async () => {
    const wrapper = await renderForm({
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
              {
                isLayout: true,
                component: 'CommonLink',
                props: {
                  external: true,
                  link: 'https://example.com',
                },
                children: [
                  {
                    type: 'text',
                    name: 'additional',
                    label: 'Additional',
                  },
                ],
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
    expect(wrapper.getByLabelText('Additional')).toBeInTheDocument()
  })

  it('can use list/group fields in form schema', async () => {
    const wrapper = await renderForm({
      props: {
        schema: [
          {
            type: 'group',
            name: 'adress',
            isGroupOrList: true,
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
                label: 'Title',
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

  it('focuses the first focusable input, if autofocus is enabled', async () => {
    const view = await renderForm({
      props: {
        shouldAutofocus: true,
      },
    })

    await waitFor(() => {
      const input = view.getByLabelText('Title')
      expect(input).toHaveFocus()
    })
  })
})

describe('Form.vue - with object attributes', () => {
  it('render form schema with object attributes', async () => {
    mockGraphQLApi(ObjectManagerFrontendAttributesDocument).willResolve({
      objectManagerFrontendAttributes: frontendObjectAttributes,
    })

    const wrapper = renderComponent(Form, {
      ...wrapperParameters,
      props: {
        useObjectAttributes: true,
        schema: [
          {
            object: EnumObjectManagerObjects.Ticket,
            name: 'title',
            screen: 'create_top',
          },
          {
            object: EnumObjectManagerObjects.Ticket,
            name: 'customer_id',
            screen: 'create_top',
          },
          {
            object: EnumObjectManagerObjects.Ticket,
            screen: 'create_middle',
          },
        ],
        initialEntityObject: {
          customer: {
            internalId: '123',
            fullname: 'John Doe',
          },
        },
      },
    })

    await waitUntil(() => wrapper.queryByLabelText('Title'))

    expect(wrapper.getByLabelText('Title')).toBeInTheDocument()
    expect(wrapper.getByLabelText('Customer')).toBeInTheDocument()
    expect(wrapper.getByLabelText('Customer')).toHaveTextContent('John Doe')
    expect(wrapper.getByLabelText('Group')).toBeInTheDocument()
    expect(wrapper.getByLabelText('State')).toBeInTheDocument()
  })

  it('render object attributes with historical options (create situation)', async () => {
    mockGraphQLApi(ObjectManagerFrontendAttributesDocument).willResolve({
      objectManagerFrontendAttributes: frontendObjectAttributes,
    })

    const wrapper = renderComponent(Form, {
      ...wrapperParameters,
      props: {
        useObjectAttributes: true,
        schema: [
          {
            object: EnumObjectManagerObjects.Ticket,
            screen: 'create_middle',
          },
        ],
        initialValues: {
          type: 'Other',
        },
      },
    })

    await waitUntil(() => wrapper.queryByLabelText('Type'))

    expect(wrapper.getByLabelText('Type')).toBeInTheDocument()
    expect(wrapper.getByLabelText('Type')).toHaveTextContent('')
  })

  it('render object attributes with historical options (edit situation)', async () => {
    mockGraphQLApi(ObjectManagerFrontendAttributesDocument).willResolve({
      objectManagerFrontendAttributes: frontendObjectAttributes,
    })

    const wrapper = renderComponent(Form, {
      ...wrapperParameters,
      props: {
        useObjectAttributes: true,
        schema: [
          {
            object: EnumObjectManagerObjects.Ticket,
            screen: 'edit',
          },
        ],
        initialEntityObject: {
          type: 'Other',
        },
      },
    })

    await waitUntil(() => wrapper.queryByLabelText('Type'))

    expect(wrapper.getByLabelText('Type')).toBeInTheDocument()
    expect(wrapper.getByLabelText('Type')).toHaveTextContent('Other')
  })

  it('focuses the first focusable input, if autofocus is enabled', async () => {
    mockGraphQLApi(ObjectManagerFrontendAttributesDocument).willResolve({
      objectManagerFrontendAttributes: frontendObjectAttributes,
    })

    const view = renderComponent(Form, {
      ...wrapperParameters,
      props: {
        shouldAutofocus: true,
        useObjectAttributes: true,
        schema: [
          {
            object: EnumObjectManagerObjects.Ticket,
            name: 'title',
            screen: 'create_top',
          },
          {
            object: EnumObjectManagerObjects.Ticket,
            name: 'customer_id',
            screen: 'create_top',
          },
          {
            object: EnumObjectManagerObjects.Ticket,
            screen: 'create_middle',
          },
        ],
        initialEntityObject: {
          customer: {
            internalId: '123',
            fullname: 'John Doe',
          },
        },
      },
    })

    await waitUntil(() => view.queryByLabelText('Title'))

    const input = view.getByLabelText('Title')
    expect(input).toHaveFocus()
  })
})

describe('Form.vue - Flatten form groups', () => {
  it('check for flat value structure on submit', async () => {
    const submitCallbackSpy = vi.fn()

    const wrapper = await renderForm({
      props: {
        id: 'multi-step-form',
        flattenFormGroups: ['step1', 'step2'],
        schema: [
          {
            type: 'group',
            name: 'step1',
            isGroupOrList: true,
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
          {
            type: 'text',
            name: 'other',
            label: 'Other',
            value: 'Some text',
          },
          {
            type: 'group',
            name: 'step2',
            isGroupOrList: true,
            children: [
              {
                type: 'text',
                name: 'title',
                label: 'Title',
              },
              {
                type: 'text',
                name: 'fullname',
                label: 'Fullname',
                value: 'John Doe',
              },
            ],
          },
        ],
        onSubmit: (data: FormValues) => submitCallbackSpy(data),
      },
    })

    await wrapper.events.type(wrapper.getByLabelText('Street'), 'Street 12')

    getNode('multi-step-form')?.submit()

    await waitForNextTick(true)

    expect(wrapper.emitted().submit).toBeTruthy()

    expect(submitCallbackSpy).toHaveBeenCalledWith({
      street: 'Street 12',
      city: '',
      other: 'Some text',
      title: '',
      fullname: 'John Doe',
    })
  })
})

describe('Form.vue - Handlers', () => {
  it('check that initial form handler is called before form creation', async () => {
    const handlerCallbackSpy = vi.fn()

    await renderForm({
      props: {
        handlers: [
          {
            execution: [FormHandlerExecution.Initial],
            callback: handlerCallbackSpy,
          },
        ],
      },
    })

    expect(handlerCallbackSpy).toHaveBeenCalledTimes(1)
  })

  it('check that initial and initial settled form handler is called once', async () => {
    const handlerCallbackInitialSpy = vi.fn()
    const handlerCallbackInitialSettledSpy = vi.fn()

    const wrapper = await renderForm({
      props: {
        handlers: [
          {
            execution: [FormHandlerExecution.Initial],
            callback: handlerCallbackInitialSpy,
          },
          {
            execution: [FormHandlerExecution.InitialSettled],
            callback: handlerCallbackInitialSettledSpy,
          },
        ],
      },
    })

    const text = wrapper.getByLabelText('Title')
    await wrapper.events.type(text, 'Example title')
    expect(text).toHaveDisplayValue('Example title')

    expect(handlerCallbackInitialSpy).toHaveBeenCalledTimes(1)
    expect(handlerCallbackInitialSettledSpy).toHaveBeenCalledTimes(1)
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

describe('Form.vue - Reset', () => {
  const assertDirty = (element: HTMLElement) => {
    expect(element.closest('.formkit-outer')).toHaveAttribute(
      'data-dirty',
      'true',
    )
  }

  const assertNotDirty = (element: HTMLElement) => {
    expect(element.closest('.formkit-outer')).not.toHaveAttribute(
      'data-dirty',
      'true',
    )
  }

  it('resets all values to original ones', async () => {
    const { view, form } = await renderTicketCreateForm()

    const input = view.getByLabelText('Title')
    const textarea = view.getByLabelText('Textarea')
    const example = view.getByLabelText('Example')
    await view.events.type(input, 'New title')
    await view.events.clear(textarea)
    await view.events.type(textarea, 'New text')
    await view.events.type(example, 'New example')

    form.value.resetForm()
    await waitForNextTick()
    expect(input).toHaveValue('')
    expect(textarea).toHaveValue('Some text')
    expect(example).toHaveValue('Some example')
  })

  it('resets all values to provided values', async () => {
    const { view, form } = await renderTicketCreateForm()
    const input = view.getByLabelText('Title')
    const textarea = view.getByLabelText('Textarea')
    const example = view.getByLabelText('Example')

    expect(input).toHaveValue('')
    expect(textarea).toHaveValue('Some text')
    expect(example).toHaveValue('Some example')

    form.value.resetForm({
      values: {
        title: 'New title',
        text: 'New text',
        example: 'New example',
      },
    })
    await waitForNextTick()
    expect(input).toHaveValue('New title')
    expect(textarea).toHaveValue('New text')
    expect(example).toHaveValue('New example')
  })

  it("doesn't reset dirty values, if asked to", async () => {
    const { view, form } = await renderTicketCreateForm()
    const input = view.getByLabelText('Title')
    const textarea = view.getByLabelText('Textarea')
    const example = view.getByLabelText('Example')

    await view.events.type(input, 'New title')
    await view.events.clear(example)
    await view.events.type(example, 'New example')

    form.value.resetForm(
      { values: { text: 'Some text' } },
      { resetDirty: false },
    )
    await waitForNextTick()

    expect(input).toHaveValue('New title')
    expect(textarea).toHaveValue('Some text')
    expect(example).toHaveValue('New example')
    expect(form.value.findNodeByName('title')?.context?.state.dirty).toBe(true)
    expect(form.value.findNodeByName('text')?.context?.state.dirty).toBe(false)
    expect(form.value.findNodeByName('example')?.context?.state.dirty).toBe(
      true,
    )
  })

  it('resets only specific group node', async () => {
    const { view, form } = await renderTicketCreateForm()

    const input = view.getByLabelText('Title')
    const textarea = view.getByLabelText('Textarea')
    const example = view.getByLabelText('Example')

    await view.events.type(input, 'New title')
    await view.events.clear(textarea)
    await view.events.type(textarea, 'New text')
    await view.events.type(example, 'New example')

    form.value.resetForm(
      {},
      { groupNode: form.value.findNodeByName('example') },
    )
    await waitForNextTick()
    expect(input).toHaveValue('New title')
    expect(textarea).toHaveValue('New text')
    expect(example).toHaveValue('Some example')
    expect(form.value.findNodeByName('title')?.context?.state.dirty).toBe(true)
    expect(form.value.findNodeByName('example')?.context?.state.dirty).toBe(
      false,
    )
  })

  it('should trigger reset form updater call', async () => {
    const mockFormUpdaterApi = mockGraphQLApi(FormUpdaterDocument).willBehave(
      (variables) => {
        const example: Partial<FormSchemaField> = {}

        if (variables.meta.reset) {
          example.value = 'Updater example'
        }

        return {
          data: {
            formUpdater: {
              fields: {
                example,
              },
              flags: {},
            },
          },
        }
      },
    )

    const { view, form } = await renderTicketCreateForm({
      formUpdaterId: EnumFormUpdaterId.FormUpdaterUpdaterTicketCreate,
    })

    await waitUntil(() => form.value.formNode)
    await getNode('form-ticket-create')?.settled

    const input = view.getByLabelText('Title')
    const textarea = view.getByLabelText('Textarea')
    const example = view.getByLabelText('Example')

    expect(input).toHaveValue('')
    expect(textarea).toHaveValue('Some text')
    expect(example).toHaveValue('Some example')

    form.value.resetForm({
      values: {
        title: 'New title',
        text: 'New text',
        example: 'New example',
      },
    })
    await waitForNextTick()

    await waitUntil(() => mockFormUpdaterApi.calls.behave === 2)

    expect(input).toHaveValue('New title')
    expect(textarea).toHaveValue('New text')
    expect(example).toHaveValue('Updater example')

    expect(mockFormUpdaterApi.spies.behave).toHaveBeenLastCalledWith(
      expect.objectContaining({
        meta: expect.objectContaining({
          reset: true,
        }),
      }),
    )
  })

  it('correctly resets state to dirty when form is submitted', async () => {
    const onSubmit = vi.fn().mockResolvedValue(true)
    const { view, form } = await renderTicketCreateForm({ onSubmit })

    const input = view.getByLabelText('Title')
    await view.events.type(input, 'New title')

    assertDirty(input)

    await view.events.click(view.getByRole('button', { name: 'Submit' }))

    expect(onSubmit).toHaveBeenCalledTimes(1)

    assertNotDirty(input)

    // restore to the initial value of empty string
    await view.events.clear(input)

    assertDirty(input)
    expect(form.value.formNode.context?.state.dirty).toBe(true)

    await view.events.type(input, 'New title')

    assertNotDirty(input)

    expect(form.value.formNode.context?.state.dirty).toBe(false)
  })

  it('clear values after submit (instead of remembering existing values)', async () => {
    const onSubmit = vi.fn().mockResolvedValue(true)
    const { view } = await renderTicketCreateForm({
      onSubmit,
      clearValuesAfterSubmit: true,
    })

    const input = view.getByLabelText('Title')
    await view.events.type(input, 'New title')

    assertDirty(input)

    await view.events.click(view.getByRole('button', { name: 'Submit' }))

    expect(onSubmit).toHaveBeenCalledTimes(1)

    expect(input).toHaveValue('')
  })
})

describe('Form.vue - Autosave notification', () => {
  const notifications = useNotifications()

  vi.spyOn(notifications, 'notify')

  beforeEach(() => {
    vi.useFakeTimers()

    mockGraphQLApi(FormUpdaterDocument).willBehave(async (variables) => {
      if (!variables.meta.initial && !variables.meta.additionalData.skipSleep) {
        await new Promise((r) => setTimeout(r, 6000))
      }

      return {
        data: {
          formUpdater: {
            fields: {},
            flags: {},
          },
        },
      }
    })
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('triggers autosave notification for slow form updater queries', async () => {
    const { view } = await renderTicketCreateForm({
      formUpdaterId: EnumFormUpdaterId.FormUpdaterUpdaterTicketCreate,
      formUpdaterAdditionalParams: {
        taskbarId: convertToGraphQLId('Taskbar', 1),
      },
    })

    await vi.runAllTimersAsync()

    const input = view.getByLabelText('Title')
    await view.events.type(input, 'New title')

    await vi.advanceTimersByTimeAsync(1500)

    expect(notifications.notify).toHaveBeenCalledWith({
      id: 'form-updater-autosave',
      message: 'Autosave in progress…',
      persistent: true,
      type: 'info',
    })

    await vi.advanceTimersByTimeAsync(4000)

    expect(notifications.notify).toHaveBeenCalledWith({
      id: 'form-updater-autosave',
      message: 'Autosaving is taking longer than expected…',
      persistent: true,
      type: 'warn',
    })
  })

  it('does not trigger autosave notification for fast form updater queries', async () => {
    const { view } = await renderTicketCreateForm({
      formUpdaterId: EnumFormUpdaterId.FormUpdaterUpdaterTicketCreate,
      formUpdaterAdditionalParams: {
        taskbarId: convertToGraphQLId('Taskbar', 1),
        skipSleep: true,
      },
    })

    await vi.runAllTimersAsync()

    const input = view.getByLabelText('Title')
    await view.events.type(input, 'New title')

    await vi.advanceTimersByTimeAsync(1500)

    expect(notifications.notify).not.toHaveBeenCalled()

    await vi.advanceTimersByTimeAsync(4000)

    expect(notifications.notify).not.toHaveBeenCalled()
  })

  it('does not trigger autosave notification without associated taskbar tab', async () => {
    const { view } = await renderTicketCreateForm({
      formUpdaterId: EnumFormUpdaterId.FormUpdaterUpdaterTicketCreate,
    })

    await vi.runAllTimersAsync()

    const input = view.getByLabelText('Title')
    await view.events.type(input, 'New title')

    await vi.advanceTimersByTimeAsync(1500)

    expect(notifications.notify).not.toHaveBeenCalled()

    await vi.advanceTimersByTimeAsync(4000)

    expect(notifications.notify).not.toHaveBeenCalled()
  })
})
