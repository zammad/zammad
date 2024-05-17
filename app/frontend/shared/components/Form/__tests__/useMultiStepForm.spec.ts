// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { type FormKitPlugin, getNode } from '@formkit/core'
import { waitFor } from '@testing-library/vue'
import { computed, ref } from 'vue'

import {
  type ExtendedMountingOptions,
  renderComponent,
} from '#tests/support/components/index.ts'
import { waitForNextTick, waitUntil } from '#tests/support/utils.ts'

import Form from '#shared/components/Form/Form.vue'
import type { Props } from '#shared/components/Form/Form.vue'
import { useMultiStepForm } from '#shared/components/Form/useMultiStepForm.ts'

const wrapperParameters = {
  form: true,
  attachTo: document.body,
  unmount: true,
}

const getSchema = (plugin: FormKitPlugin) => {
  return [
    {
      type: 'group',
      name: 'step1',
      isGroupOrList: true,
      plugins: [plugin],
      children: [
        {
          type: 'text',
          name: 'title',
          label: 'Title',
          required: true,
        },
      ],
    },
    {
      type: 'group',
      name: 'step2',
      isGroupOrList: true,
      plugins: [plugin],
      children: [
        {
          type: 'textarea',
          name: 'text',
          label: 'Text',
        },
      ],
    },
  ]
}

const reactiveRef = ref(1)

// Initialize a form component.
const renderForm = async (options: ExtendedMountingOptions<Props> = {}) => {
  const wrapper = renderComponent(Form, {
    ...wrapperParameters,
    ...options,
    attrs: {
      id: 'test-form',
    },
    props: { ...(options.props || {}) },
  })

  await waitUntil(() => wrapper.emitted().settled)

  reactiveRef.value += 1
  return wrapper
}

const formNode = computed(() => {
  if (!reactiveRef.value) return
  return getNode('test-form')
})

describe('useMultiStepForm', () => {
  it('check default active step', async () => {
    const { multiStepPlugin, activeStep } = useMultiStepForm(formNode)

    await renderForm({
      props: {
        schema: getSchema(multiStepPlugin),
      },
    })

    expect(activeStep.value).toStrictEqual('step1')
  })

  it('check all steps', async () => {
    const { multiStepPlugin, allSteps } = useMultiStepForm(formNode)

    await renderForm({
      props: {
        schema: getSchema(multiStepPlugin),
      },
    })

    expect(allSteps.value).toEqual({
      step1: {
        completed: false,
        disabled: true,
        errorCount: 1,
        label: '1',
        order: 1,
        valid: false,
      },
      step2: {
        completed: false,
        disabled: true,
        errorCount: 0,
        label: '2',
        order: 2,
        valid: true,
      },
    })
  })

  it('check step names', async () => {
    const { multiStepPlugin, stepNames } = useMultiStepForm(formNode)

    await renderForm({
      props: {
        schema: getSchema(multiStepPlugin),
      },
    })

    expect(stepNames.value).toStrictEqual(['step1', 'step2'])
  })

  it('check visited step after step switch', async () => {
    const { multiStepPlugin, setMultiStep, visitedSteps } =
      useMultiStepForm(formNode)

    await renderForm({
      props: {
        schema: getSchema(multiStepPlugin),
      },
    })

    // Go to next step.
    setMultiStep()
    await waitForNextTick()

    expect(visitedSteps.value).toStrictEqual(['step1'])

    // Go to next step.
    setMultiStep()
    await waitForNextTick()

    expect(visitedSteps.value).toStrictEqual(['step1', 'step2'])
  })

  it('triggers autofocus of the first input in the step', async () => {
    const { multiStepPlugin, setMultiStep } = useMultiStepForm(formNode)

    const wrapper = await renderForm({
      props: {
        schema: getSchema(multiStepPlugin),
      },
    })

    // Go to next step.
    setMultiStep()

    await waitFor(() => {
      expect(wrapper.getByLabelText('Title')).toHaveFocus()
    })

    // NB: Due to the test environment not being able to determine whether a focusable element is visible or not
    //   and multi step sections being hidden via CSS rules, we can test only one (first) step here.
  })
})
