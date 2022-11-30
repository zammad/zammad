// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { createMessage, getNode } from '@formkit/core'
import type { FormKitNode } from '@formkit/core'
import { computed, shallowRef, toRef, ref, reactive, watch } from 'vue'
import type { ShallowRef, Ref } from 'vue'
import type { CommonStepperStep } from '@mobile/components/CommonStepper'

export interface FormRef {
  formNode: FormKitNode
}

// TODO: only a start, needs to be extended during the way...
export const useForm = () => {
  const form: ShallowRef<FormRef | undefined> = shallowRef()

  const node = computed(() => form.value?.formNode)

  const context = computed(() => node.value?.context)

  const values = computed(() => context.value?.value)

  const state = computed(() => context.value?.state)

  const isValid = computed(() => !!state.value?.valid)

  const isDirty = computed(() => !!state.value?.dirty)

  const isComplete = computed(() => !!state.value?.complete)

  const isSubmitted = computed(() => !!state.value?.submitted)

  const isDisabled = computed(() => {
    return !!context.value?.disabled || !!state.value?.formUpdaterProcessing
  })

  const formReset = () => {
    node.value?.reset()
  }

  const formSubmit = () => {
    node.value?.submit()
  }

  return {
    form,
    node,
    context,
    values,
    state,
    isValid,
    isDirty,
    isComplete,
    isSubmitted,
    isDisabled,
    formReset,
    formSubmit,
  }
}

interface InternalMultiFormSteps {
  label: string
  order: number
  valid: Ref<boolean>
  blockingCount: number
  errorCount: number
}

export const useMultiStepForm = () => {
  const activeStep = ref('')
  const internalSteps = reactive<Record<string, InternalMultiFormSteps>>({})
  const visitedSteps = ref<string[]>([])
  const stepNames = computed(() => Object.keys(internalSteps))

  const lastStepName = computed(
    () => stepNames.value[stepNames.value.length - 1],
  )

  // Watch the active steps to track the visited steps.
  watch(activeStep, (newStep, oldStep) => {
    if (oldStep && !visitedSteps.value.includes(oldStep)) {
      visitedSteps.value.push(oldStep)
    }

    // Trigger showing validation on fields within all visited steps, otherwise it would only visible
    // after clicking on the "real" submit button.
    visitedSteps.value.forEach((step) => {
      const node = getNode(step)

      if (!node) return

      node.walk((fieldNode) => {
        fieldNode.store.set(
          createMessage({
            key: 'submitted',
            value: true,
            visible: false,
          }),
        )
      })
    })
  })

  const setMultiStep = (step?: string) => {
    // Go to next step, when no specific step is given.
    if (!step) {
      const currentIndex = stepNames.value.indexOf(activeStep.value)
      activeStep.value = stepNames.value[currentIndex + 1]
    } else {
      activeStep.value = step
    }
  }

  const multiStepPlugin = (node: FormKitNode) => {
    if (node.props.type === 'group') {
      internalSteps[node.name] = internalSteps[node.name] || {}

      node.on('created', () => {
        if (!node.context) return

        internalSteps[node.name].valid = toRef(node.context.state, 'valid')
        internalSteps[node.name].label =
          Object.keys(internalSteps).length.toString()
        internalSteps[node.name].order = Object.keys(internalSteps).length
      })

      // Listen for changes in error count, which a normally errors from the backend after submitting.
      node.on('count:errors', ({ payload: count }) => {
        internalSteps[node.name].errorCount = count
      })

      // Listen for changes in count of blocking validations messages.
      node.on('count:blocking', ({ payload: count }) => {
        internalSteps[node.name].blockingCount = count
      })

      // The first step should be the default one.
      if (activeStep.value === '') {
        activeStep.value = node.name
      }
    }

    return false
  }

  const allSteps = computed<Record<string, CommonStepperStep>>(() => {
    const mappedSteps: Record<string, CommonStepperStep> = {}

    stepNames.value.forEach((stepName) => {
      const alreadyVisisted = visitedSteps.value.includes(stepName)

      mappedSteps[stepName] = {
        label: internalSteps[stepName].label,
        order: internalSteps[stepName].order,
        errorCount:
          internalSteps[stepName].blockingCount +
          internalSteps[stepName].errorCount,
        valid:
          internalSteps[stepName].valid &&
          internalSteps[stepName].errorCount === 0,
        disabled: !alreadyVisisted || activeStep.value === stepName,
        completed: alreadyVisisted,
      }
    })

    return mappedSteps
  })

  return {
    multiStepPlugin,
    setMultiStep,
    allSteps,
    stepNames,
    lastStepName,
    activeStep,
    visitedSteps,
  }
}
