// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitPlugin } from '@formkit/core'
import Form from '@shared/components/Form/Form.vue'
import type { Props } from '@shared/components/Form/Form.vue'
import { useMultiStepForm } from '@shared/components/Form/composable'
import {
  type ExtendedMountingOptions,
  renderComponent,
} from '@tests/support/components'
import { waitForNextTick, waitUntil } from '@tests/support/utils'

const wrapperParameters = {
  form: true,
  attachTo: document.body,
  unmount: false,
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

// Initialize a form component.
const renderForm = async (options: ExtendedMountingOptions<Props> = {}) => {
  const wrapper = renderComponent(Form, {
    ...wrapperParameters,
    ...options,
    props: { ...(options.props || {}) },
  })

  await waitUntil(() => wrapper.emitted().settled)

  return wrapper
}

describe('useMultiStepForm', () => {
  it('check default active step', async () => {
    const { multiStepPlugin, activeStep } = useMultiStepForm()

    await renderForm({
      props: {
        schema: getSchema(multiStepPlugin),
      },
    })

    expect(activeStep.value).toStrictEqual('step1')
  })

  it('check all steps', async () => {
    const { multiStepPlugin, allSteps } = useMultiStepForm()

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
    const { multiStepPlugin, stepNames } = useMultiStepForm()

    await renderForm({
      props: {
        schema: getSchema(multiStepPlugin),
      },
    })

    expect(stepNames.value).toStrictEqual(['step1', 'step2'])
  })

  it('check visited step after step switch', async () => {
    const { multiStepPlugin, setMultiStep, visitedSteps } = useMultiStepForm()

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
})
