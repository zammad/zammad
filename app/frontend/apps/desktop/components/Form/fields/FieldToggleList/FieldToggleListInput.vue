<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'
import useValue from '#shared/components/Form/composables/useValue.ts'
import { i18n } from '#shared/i18n.ts'
import { useDelegateFocus } from '#shared/composables/useDelegateFocus.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import type { ToggleListOption, ToggleListOptionValue } from './types.ts'

const props = defineProps<{
  context: FormFieldContext<{
    options: ToggleListOption[]
  }>
}>()

const context = toRef(props, 'context')

const { localValue } = useValue(context)

const valueLookup = computed<Record<string, boolean>>(() => {
  const values: ToggleListOptionValue[] = localValue.value || []

  return values.reduce((value: Record<string, boolean>, key) => {
    value[key] = true

    return value
  }, {})
})

const updateValue = (
  key: ToggleListOptionValue,
  state: boolean | undefined,
) => {
  const values: ToggleListOptionValue[] = localValue.value || []

  if (state === true && !values.includes(key)) {
    values.push(key)
    localValue.value = values
  } else if (state === false) {
    localValue.value = values.filter((value) => value !== key)
  }
}

const { delegateFocus } = useDelegateFocus(
  context.value.id,
  `toggle_list_toggle_${context.value.id}_${context.value.options[0]?.value}`,
)
</script>

<template>
  <output
    :id="context.id"
    class="block bg-blue-200 dark:bg-gray-700 rounded-lg focus:outline-none"
    role="list"
    :class="context.classes.input"
    :name="context.node.name"
    :aria-disabled="context.disabled"
    :tabindex="context.disabled ? '-1' : '0'"
    v-bind="context.attrs"
    @focus="delegateFocus"
  >
    <div
      v-for="(option, index) in context.options"
      :key="`option-${option.value}`"
      class="flex gap-2.5 items-center px-3 py-2.5"
      role="option"
    >
      <FormKit
        :id="`toggle_list_toggle_${context.id}_${option.value}`"
        :model-value="valueLookup[option.value]"
        type="toggle"
        :name="`toggle_list_toggle_${context.id}_${option.value}`"
        wrapper-class="gap-2.5"
        :variants="{ true: 'True', false: 'False' }"
        :disabled="context.disabled"
        size="small"
        :label="$t(option.label)"
        :sections-schema="{
          label: {
            attrs: {
              class: 'flex flex-col',
              for: `toggle_list_toggle_${context.id}_${option.value}`,
            },
            children: [
              {
                $cmp: 'CommonLabel',
                props: {
                  class: 'text-black dark:text-white',
                },
                children: '$label',
              },
              {
                $cmp: 'CommonLabel',
                props: {
                  class: 'text-stone-200 dark:text-neutral-500',
                },
                children: i18n.t(option.description),
              },
            ],
          },
        }"
        @update:model-value="updateValue(option.value, $event)"
        @blur="index === 0 ? context.handlers.blur : undefined"
      />
    </div>
  </output>
</template>
