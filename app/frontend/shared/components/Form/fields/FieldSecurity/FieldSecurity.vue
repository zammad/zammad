<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useTraverseOptions } from '@shared/composables/useTraverseOptions'
import { computed, ref, toRef } from 'vue'
import useValue from '../../composables/useValue'
import type { SecurityOption, SecurityValue, SecurityAllowed } from './types'
import type { FormFieldContext } from '../../types/field'

interface FieldSecurityProps {
  context: FormFieldContext<{
    disabled?: boolean
    allowed?: SecurityAllowed
  }>
}

const props = defineProps<FieldSecurityProps>()

const { currentValue } = useValue<SecurityValue>(toRef(props, 'context'))

const isCurrentValue = (option: SecurityOption) =>
  currentValue.value?.includes(option) ?? false

const options = computed(() => {
  return [
    {
      option: 'encryption',
      label: 'Encrypt',
      icon: isCurrentValue('encryption') ? 'mobile-lock' : 'mobile-unlock',
    },
    {
      option: 'sign',
      label: 'Sign',
      icon: isCurrentValue('sign') ? 'mobile-signed' : 'mobile-not-signed',
    },
  ] as const
})

const isDisabled = (option: SecurityOption) =>
  props.context.disabled || !props.context.allowed?.includes(option)

const toggleOption = (name: SecurityOption) => {
  if (isDisabled(name)) return
  let currentOptions = currentValue.value || []

  if (currentOptions.includes(name))
    currentOptions = currentOptions.filter((option) => option !== name)
  else currentOptions = [...currentOptions, name]

  props.context.node.input(currentOptions.sort())
}

const optionsContainer = ref<HTMLElement>()

useTraverseOptions(optionsContainer, { direction: 'horizontal' })
</script>

<template>
  <div
    ref="optionsContainer"
    role="listbox"
    class="flex h-full items-center gap-2"
    :aria-label="context.label"
    aria-multiselectable="true"
    aria-orientation="horizontal"
  >
    <button
      v-for="{ option, label, icon } of options"
      :key="option"
      role="option"
      type="button"
      class="flex select-none items-center gap-1 rounded-md px-2 py-1 text-base"
      :class="{
        'bg-gray-600/50 text-white/30': isDisabled(option),
        'cursor-pointer': !isDisabled(option),
        'bg-gray-300 text-white': !isCurrentValue(option),
        'bg-white font-semibold text-black': isCurrentValue(option),
      }"
      :tabindex="isDisabled(option) ? -1 : 0"
      :disabled="isDisabled(option)"
      :aria-selected="isCurrentValue(option)"
      :aria-disabled="isDisabled(option)"
      @click="toggleOption(option)"
      @keydown.space.prevent="toggleOption(option)"
    >
      <CommonIcon :name="icon" size="tiny" decorative />
      {{ $t(label) }}
    </button>
  </div>
</template>
