<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import stopEvent from '@shared/utils/events'
import { computed, nextTick, toRef, watch } from 'vue'
import useValue from '../../composables/useValue'
import type { FormFieldContext } from '../../types/field'

const props = defineProps<{
  context: FormFieldContext<{
    // TODO: need to be changed to "options", because otherwise core workflow can not handle this
    variants?: {
      true?: string
      false?: string
    }
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

  // if ca't select next value, disable the toggle
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
</script>

<template>
  <input
    :id="context.id"
    class="hidden"
    type="checkbox"
    tabindex="-1"
    :disabled="disabled"
    :checked="localValue"
    @change="updateLocalValue"
  />
  <div
    class="relative inline-flex h-6 w-10 flex-shrink-0 cursor-pointer rounded-full border border-transparent bg-gray-300 transition-colors duration-200 ease-in-out focus-within:ring-1 focus-within:ring-white focus-within:ring-opacity-75 focus:outline-none formkit-invalid:border-solid formkit-invalid:border-red"
    :class="{
      '!bg-blue': localValue,
    }"
    aria-hidden="true"
    :tabindex="props.context.disabled ? '-1' : '0'"
    @click="updateLocalValue"
    @keydown.space="updateLocalValue"
  >
    <div
      class="pointer-events-none inline-block h-[22px] w-[22px] translate-x-0 transform rounded-full bg-white shadow-lg ring-0 transition duration-200 ease-in-out"
      :class="{
        'translate-x-4': localValue,
      }"
    ></div>
  </div>
</template>
