// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { createMessage, getNode, type FormKitNode } from '@formkit/core'

import { renderComponent } from '#tests/support/components/index.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import Form from '#shared/components/Form/Form.vue'
import { useForm } from '#shared/components/Form/useForm.ts'

import { FormValidationVisibility } from '../types.ts'

import type { FormRef, FormValues } from '../types.ts'

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
    delay: 20, // Add default delay to simulate live situation.
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

const getFormContext = (): FormRef => {
  return {
    formId: 'test-form',
    formInitialSettled: true,
    formNode: getNode('test-form') as FormKitNode,
    values: getNode('test-form')?.value as FormValues,
    flags: {},
    updateChangedFields: vi.fn(),
    updateSchemaDataField: vi.fn(),
    getNodeByName: vi.fn(),
    findNodeByName: vi.fn(),
    resetForm: vi.fn(),
    triggerFormUpdater: vi.fn(),
  }
}

describe('useForm', () => {
  // Initialize a form component.

  it('existing form node', () => {
    renderForm()
    const { form, node } = useForm()

    form.value = getFormContext()

    const currentNode = node.value as FormKitNode

    expect(currentNode.value).toBeDefined()
    expect(currentNode.value).toStrictEqual({
      title: '',
      text: 'Some text',
    })
  })

  it('use different states', () => {
    renderForm()
    const { form, isValid, isDirty, isComplete, isSubmitted, isDisabled } =
      useForm()

    form.value = getFormContext()

    expect(isValid.value).toBe(true)
    expect(isDirty.value).toBe(false)
    expect(isComplete.value).toBe(false)
    expect(isSubmitted.value).toBe(false)
    expect(isDisabled.value).toBe(false)
  })

  it('form updater flag is true when form updater is processing', async () => {
    renderForm()
    const { form, isFormUpdaterRunning } = useForm()

    const formNode = getNode('test-form') as FormKitNode

    form.value = getFormContext()

    formNode.store.set(
      createMessage({
        blocking: true,
        key: 'formUpdaterProcessing',
        value: true,
        visible: false,
      }),
    )

    expect(isFormUpdaterRunning.value).toBe(true)
  })

  it('use values', () => {
    renderForm()
    const { form, values } = useForm()

    form.value = getFormContext()

    expect(values.value).toStrictEqual({
      title: '',
      text: 'Some text',
    })
  })

  it('use form submit', async () => {
    const wrapper = renderForm()
    const { form, formSubmit } = useForm()

    form.value = getFormContext()

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

  it('can register on change event of singlem field', async () => {
    const onChangedFieldCallbackSpy = vi.fn()

    const { view, utils } = renderForm()
    const { form, onChangedField } = utils

    // Register callback on changed title field.
    onChangedField('title', onChangedFieldCallbackSpy)

    await view.events.debounced(() =>
      view.events.type(view.getByLabelText('Title'), 'Some title'),
    )

    expect(onChangedFieldCallbackSpy).toHaveBeenCalledWith(
      'Some title',
      '',
      form.value?.getNodeByName('title'),
    )
  })
})
