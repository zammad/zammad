// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '@tests/support/components'
import { ref } from 'vue'
import CommonStepper from '../CommonStepper.vue'
import type { CommonStepperStep } from '../types'

describe('stepper component', () => {
  test('renders valid steps', async () => {
    const modelValue = ref('step1')
    const steps: Record<string, CommonStepperStep> = {
      step1: {
        label: '1',
        order: 1,
        errorCount: 0,
        valid: true,
        disabled: false,
        completed: true,
      },
      step2: {
        label: '2',
        order: 2,
        errorCount: 0,
        valid: true,
        disabled: false,
        completed: false,
      },
      step3: {
        label: '3',
        order: 3,
        errorCount: 0,
        valid: true,
        completed: false,
        disabled: true,
      },
      step4: {
        label: '4',
        order: 4,
        errorCount: 3,
        valid: false,
        completed: true,
        disabled: true,
      },
    }
    const view = renderComponent(CommonStepper, {
      props: {
        steps,
      },
      vModel: {
        modelValue,
      },
    })

    await view.events.click(view.getByText('2'))

    expect(modelValue.value).toBe('step2')

    expect(
      view.getByRole('status', { name: 'Invalid values in step 4' }),
    ).toHaveTextContent('3')

    expect(
      view.getByRole('button', { name: 'Step 1 is completed' }),
    ).toBeInTheDocument()

    await view.events.click(view.getByRole('button', { name: '3' }))

    expect(modelValue.value).toBe('step2')
  })
})
