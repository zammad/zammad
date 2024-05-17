<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, nextTick, toRef, watch } from 'vue'

import stopEvent from '#shared/utils/events.ts'

import useValue from '../../composables/useValue.ts'

import { getToggleClasses } from './initializeToggleClasses.ts'

import type { FormFieldContext } from '../../types/field.ts'

const props = defineProps<{
  context: FormFieldContext<{
    // TODO: need to be changed to "options", because otherwise core workflow can not handle this
    variants?: {
      true?: string
      false?: string
    }
    size?: 'medium' | 'small'
  }>
}>()

const context = toRef(props, 'context')
const { localValue } = useValue(context)

const variants = computed(() => props.context.variants || {})

watch(
  () => props.context.variants,
  (variants) => {
    if (!variants) {
      console.warn(
        'FieldToggleInput: variants prop is required, but not provided',
      )
      return
    }

    if (localValue.value === undefined) {
      const options = Object.keys(variants)
      if (options.length === 1) {
        nextTick(() => {
          localValue.value = options[0] === 'true'
        })
      }
      return
    }

    const valueString = localValue.value ? 'true' : 'false'

    // if current value is not removed from options, we don't need to reset it
    if (valueString in variants) return

    // current value was removed from options, so we need reset it
    // if other value exists, fallback to it, otherwise set to undefined
    const newValueString = localValue.value ? 'false' : 'true'
    const newValue = newValueString in variants ? !localValue.value : undefined

    localValue.value = newValue
  },
  { immediate: true },
)

const disabled = computed(() => {
  if (props.context.disabled) return true

  const nextValueString = localValue.value ? 'false' : 'true'

  // if can't select next value, disable the toggle
  return !(nextValueString in variants.value)
})

const updateLocalValue = (e: Event) => {
  stopEvent(e)

  if (disabled.value) return

  const newValue = localValue.value ? 'false' : 'true'

  if (newValue in variants.value) {
    localValue.value = newValue === 'true'
  }
}

const ariaChecked = computed(() => (localValue.value ? 'true' : 'false'))

const buttonSizeClasses = computed(() => {
  if (context.value.size === 'small') return 'w-8 h-5'

  return 'w-10 h-6'
})

const knobSizeClasses = computed(() => {
  if (context.value.size === 'small') return 'w-[18px] h-[18px]'

  return 'w-[22px] h-[22px]'
})

const knobTranslateClasses = computed(() => {
  if (context.value.size === 'small')
    return 'ltr:translate-x-[13px] rtl:-translate-x-[13px]'

  return 'ltr:translate-x-[17px] rtl:-translate-x-[17px]'
})

const classMap = getToggleClasses()
</script>

<template>
  <button
    :id="context.id"
    type="button"
    role="switch"
    class="formkit-disabled:pointer-events-none relative inline-flex flex-shrink-0 cursor-pointer items-center rounded-full transition-colors duration-200 ease-in-out"
    :class="[
      context.classes.input,
      classMap.track,
      buttonSizeClasses,
      {
        [classMap.trackOn]: localValue,
      },
    ]"
    :aria-labelledby="`label-${context.id}`"
    :aria-disabled="disabled"
    :aria-checked="ariaChecked"
    :aria-describedby="context.describedBy"
    :tabindex="context.disabled ? '-1' : '0'"
    :v-bind="context.attrs"
    @click="updateLocalValue"
    @keydown.space="updateLocalValue"
  >
    <div
      class="pointer-events-none inline-block transform rounded-full transition duration-200 ease-in-out"
      :class="[
        classMap.knob,
        knobSizeClasses,
        {
          'ltr:translate-x-px rtl:-translate-x-px': !localValue,
          [knobTranslateClasses]: localValue,
        },
      ]"
    ></div>
  </button>
</template>
