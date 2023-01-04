// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import Form from '@shared/components/Form/Form.vue'
import { useForm } from '@shared/components/Form/composable'
import { createMessage, getNode, type FormKitNode } from '@formkit/core'
import { renderComponent } from '@tests/support/components'
import { waitForNextTick } from '@tests/support/utils'
import { FormValidationVisibility } from '../types'

const wrapperParameters = {
  form: true,
  attachTo: document.body,
  unmount: true,
}

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

const renderForm = (options: any = {}) => {
  return renderComponent(Form, {
    ...wrapperParameters,
    attrs: {
      id: 'test-form',
    },
    props: {
      schema,
    },
    ...options,
  })
}

describe('useForm', () => {
  // Initialize a form component.

  it('existing form node', () => {
    renderForm()
    const { form, node } = useForm()

    form.value = {
      formNode: getNode('test-form') as FormKitNode,
      resetForm: vi.fn(),
    }

    const currentNode = node.value as FormKitNode

    expect(currentNode.value).toBeDefined()
    expect(currentNode.value).toStrictEqual({
      title: undefined,
      text: 'Some text',
    })
  })

  it('use different states', () => {
    renderForm()
    const { form, isValid, isDirty, isComplete, isSubmitted, isDisabled } =
      useForm()

    form.value = {
      formNode: getNode('test-form') as FormKitNode,
      resetForm: vi.fn(),
    }

    expect(isValid.value).toBe(true)
    expect(isDirty.value).toBe(false)
    expect(isComplete.value).toBe(false)
    expect(isSubmitted.value).toBe(false)
    expect(isDisabled.value).toBe(false)
  })

  it('disabled when form updater is processing', async () => {
    renderForm()
    const { form, isDisabled } = useForm()

    const formNode = getNode('test-form') as FormKitNode

    form.value = {
      formNode,
      resetForm: vi.fn(),
    }

    formNode.store.set(
      createMessage({
        blocking: true,
        key: 'formUpdaterProcessing',
        value: true,
        visible: false,
      }),
    )

    expect(isDisabled.value).toBe(true)
  })

  it('use values', () => {
    renderForm()
    const { form, values } = useForm()

    form.value = {
      formNode: getNode('test-form') as FormKitNode,
      resetForm: vi.fn(),
    }

    expect(values.value).toStrictEqual({
      title: undefined,
      text: 'Some text',
    })
  })

  it('use form submit', async () => {
    const wrapper = renderForm()
    const { form, formSubmit } = useForm()

    form.value = {
      formNode: getNode('test-form') as FormKitNode,
      resetForm: vi.fn(),
    }

    formSubmit()
    await waitForNextTick()

    expect(wrapper.emitted().submit).toBeTruthy()
  })
})

describe('submitting form rules', () => {
  const renderForm = (props: any = {}) => {
    let form!: ReturnType<typeof useForm>
    const view = renderComponent(
      {
        components: { Form },
        template: `
        <Form ref="form" id="form" :schema="schema" v-bind="custom" @submit="onSubmit" />
        <button form="form" :disabled="!canSubmit">Submit</button>
        `,
        setup() {
          form = useForm()

          const onSubmit = async () => {
            // noop
            return 0
          }

          return {
            ...form,
            schema,
            onSubmit,
            custom: props,
          }
        },
      },
      {
        form: true,
        attachTo: document.body,
      },
    )
    return {
      view,
      utils: form,
    }
  }

  it('cannot submit form, when nothing changed, and can submit, when value changes', async () => {
    const { view, utils } = renderForm()
    const { canSubmit, form } = utils

    expect(form.value?.formNode).toBeDefined()
    expect(canSubmit.value).toBeFalsy()

    await view.events.debounced(() =>
      view.events.type(view.getByLabelText('Title'), 'Some title'),
    )

    expect(canSubmit.value).toBeTruthy()
  })

  it('cannot change disabled form', () => {
    const { utils } = renderForm({ disabled: true })
    const { canSubmit, isDisabled, form } = utils

    expect(form.value?.formNode).toBeDefined()
    expect(isDisabled.value).toBeTruthy()
    expect(canSubmit.value).toBeFalsy()
  })

  it('cannot change invalid form', () => {
    const { utils } = renderForm({
      validationVisibility: FormValidationVisibility.Live,
      schema: [
        {
          ...schema[0],
          required: true,
        },
        schema[1],
      ],
    })
    const { canSubmit, isValid, form } = utils

    expect(form.value?.formNode).toBeDefined()
    expect(isValid.value).toBeFalsy()
    expect(canSubmit.value).toBeFalsy()
  })

  it('can change form, after it was submitted', async () => {
    const { view, utils } = renderForm()
    const { canSubmit, form } = utils

    expect(form.value?.formNode).toBeDefined()
    expect(canSubmit.value).toBeFalsy()

    await view.events.debounced(() =>
      view.events.type(view.getByLabelText('Title'), 'Some title'),
    )

    expect(canSubmit.value).toBeTruthy()

    await view.events.click(view.getByText('Submit'))

    // will work, only if @submit is async
    // or manually called "resetForm"
    expect(canSubmit.value).toBeFalsy()
  })
})
