// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { createMessage, getNode } from '@formkit/core'
import { computed, toRef, ref, reactive, watch } from 'vue'

import type { FormStep } from './types.ts'
import type { FormKitNode } from '@formkit/core'
import type { ComputedRef, Ref } from 'vue'

interface InternalMultiFormSteps {
  label: string
  order: number
  valid: Ref<boolean>
  blockingCount: number
  errorCount: number
}

export const useMultiStepForm = (
  formNode: ComputedRef<FormKitNode | undefined>,
) => {
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

    formNode.value?.emit('autofocus')
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

  const allSteps = computed<Record<string, FormStep>>(() => {
    const mappedSteps: Record<string, FormStep> = {}

    stepNames.value.forEach((stepName) => {
      const alreadyVisited = visitedSteps.value.includes(stepName)

      mappedSteps[stepName] = {
        label: internalSteps[stepName].label,
        order: internalSteps[stepName].order,
        errorCount:
          internalSteps[stepName].blockingCount +
          internalSteps[stepName].errorCount,
        valid:
          internalSteps[stepName].valid &&
          internalSteps[stepName].errorCount === 0,
        disabled: !alreadyVisited || activeStep.value === stepName,
        completed: alreadyVisited,
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
