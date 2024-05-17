<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { toRef } from 'vue'

import CommonLabel from '#shared/components/CommonLabel/CommonLabel.vue'
import useValue from '#shared/components/Form/composables/useValue.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import { useDelegateFocus } from '#shared/composables/useDelegateFocus.ts'

import type { RadioListOption } from './types.ts'

const props = defineProps<{
  context: FormFieldContext<{
    options: RadioListOption[]
  }>
}>()

const context = toRef(props, 'context')

const { localValue } = useValue(context)

const { delegateFocus } = useDelegateFocus(
  context.value.id,
  `radio_list_radio_${context.value.id}_${context.value?.options && context.value?.options[0]?.value}`,
)

const selectOption = (option: RadioListOption, event?: Event) => {
  localValue.value = option.value

  const targetElement = (event?.target as Element)
    ?.closest('.group')
    ?.querySelector('.icon') as HTMLElement

  targetElement?.focus()
}
</script>

<template>
  <output
    :id="context.id"
    class="flex flex-col items-start rounded-lg bg-blue-200 focus:outline focus:outline-1 focus:outline-offset-1 focus:outline-blue-800 hover:focus:outline-blue-800 dark:bg-gray-700"
    role="radiogroup"
    :class="context.classes.input"
    :name="context.node.name"
    :aria-disabled="context.disabled"
    :aria-describedby="context.describedBy"
    tabindex="0"
    v-bind="context.attrs"
    @focus="delegateFocus"
  >
    <!-- eslint-disable vuejs-accessibility/interactive-supports-focus   -->
    <div
      v-for="option in context.options"
      :key="`option-${option.value}`"
      class="group inline-flex cursor-pointer gap-2.5 px-3 py-2.5"
      role="radio"
      :aria-disabled="context.disabled"
      :aria-checked="option.value == localValue"
      :aria-label="option.label"
      @click.stop="selectOption(option, $event)"
      @keydown.enter.stop="selectOption(option, $event)"
    >
      <CommonIcon
        :id="`radio_list_radio_${context.id}_${option.value}`"
        size="small"
        tabindex="0"
        class="formkit-disabled:pointer-events-none formkit-invalid:outline-red-500 dark:hover:formkit-invalid:outline-red-500 formkit-errors:outline formkit-errors:outline-1 formkit-errors:-outline-offset-1 formkit-errors:outline-red-500 dark:hover:formkit-errors:outline-red-500 shrink-0 self-start rounded-full focus:outline focus:outline-1 focus:-outline-offset-1 focus:outline-blue-800 group-hover:outline group-hover:outline-1 group-hover:-outline-offset-1 group-hover:outline-blue-600 group-hover:focus:outline-blue-800 dark:group-hover:outline-blue-900 dark:group-hover:focus:outline-blue-800"
        :name="option.value == localValue ? 'radio-yes' : 'radio-no'"
        @keydown.space.prevent="selectOption(option)"
      />

      <div class="flex flex-col" tabindex="-1">
        <CommonLabel class="text-black dark:text-white">
          {{ $t(option.label) }}
        </CommonLabel>

        <CommonLabel
          v-if="option.description"
          class="text-stone-200 dark:text-neutral-500"
        >
          {{ $t(option.description) }}
        </CommonLabel>
      </div>
    </div>
  </output>
</template>
