<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { markRaw, ref, toRef, watch } from 'vue'

import useValue from '#shared/components/Form/composables/useValue.ts'
import type {
  AutoCompleteOption,
  AutoCompleteProps,
  AutocompleteSelectValue,
} from '#shared/components/Form/fields/FieldAutocomplete/types.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import useSelectOptions from '#shared/composables/useSelectOptions.ts'
import { useFormBlock } from '#shared/form/useFormBlock.ts'
import { i18n } from '#shared/i18n.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

import { useDialog } from '#mobile/composables/useDialog.ts'

interface Props {
  context: FormFieldContext<AutoCompleteProps>
}

const props = defineProps<Props>()
const contextReactive = toRef(props, 'context')

const { hasValue, valueContainer, currentValue, clearValue } =
  useValue<AutocompleteSelectValue>(contextReactive)

const localOptions = ref(props.context.options || [])

watch(
  () => props.context.options,
  (options) => {
    localOptions.value = options || []
  },
)

const nameDialog = `field-auto-complete-${props.context.id}`

const dialog = useDialog({
  name: nameDialog,
  prefetch: true,
  component: () => import('./FieldAutoCompleteInputDialog.vue'),
})

const openModal = () => {
  return dialog.open({
    context: contextReactive,
    name: nameDialog,
    options: localOptions,
    optionIconComponent: props.context.optionIconComponent
      ? markRaw(props.context.optionIconComponent)
      : null,
    onUpdateOptions: (options: AutoCompleteOption[]) => {
      localOptions.value = options
    },
    onAction() {
      props.context.onActionClick?.()
    },
  })
}

const {
  optionValueLookup,
  getSelectedOptionIcon,
  getSelectedOptionValue,
  getSelectedOptionLabel,
} = useSelectOptions(localOptions, contextReactive)

// Remember current optionValueLookup in node context.
contextReactive.value.optionValueLookup = optionValueLookup

// Initial options prefill for non-multiple fields (multiple fields needs to be handled in the form updater).
if (
  !props.context.multiple &&
  hasValue.value &&
  props.context.initialOptionBuilder &&
  !getSelectedOptionLabel(currentValue.value)
) {
  const initialOption = props.context.initialOptionBuilder(
    props.context.node.at('$root')?.context?.initialEntityObject as ObjectLike,
    currentValue.value,
    props.context,
  )

  if (initialOption) localOptions.value.push(initialOption)
}

const toggleDialog = async (isVisible: boolean) => {
  if (isVisible) {
    await openModal()
    return
  }

  await dialog.close()
}

const onInputClick = () => {
  if (dialog.isOpened.value) return
  toggleDialog(true)
}

useFormBlock(contextReactive, onInputClick)
</script>

<template>
  <div
    :class="{
      [context.classes.input]: true,
      'ltr:pr-9 rtl:pl-9': context.clearable && hasValue && !context.disabled,
    }"
    class="flex h-auto rounded-none bg-transparent"
    data-test-id="field-autocomplete"
  >
    <output
      :id="context.id"
      role="combobox"
      :name="context.node.name"
      class="formkit-disabled:pointer-events-none flex grow items-center focus:outline-none"
      :aria-disabled="context.disabled ? 'true' : undefined"
      :aria-labelledby="`label-${context.id}`"
      aria-haspopup="dialog"
      aria-autocomplete="none"
      :aria-controls="`dialog-${nameDialog}`"
      :aria-owns="`dialog-${nameDialog}`"
      :aria-expanded="dialog.isOpened.value"
      tabindex="0"
      :data-multiple="context.multiple ? 'true' : undefined"
      v-bind="context.attrs"
      @keyup.shift.down.prevent="toggleDialog(true)"
      @keypress.space.prevent="toggleDialog(true)"
      @blur="context.handlers.blur"
    >
      <div v-if="hasValue" class="flex grow flex-wrap gap-1" role="list">
        <div
          v-for="(selectedValue, idx) in valueContainer"
          :key="getSelectedOptionValue(selectedValue)?.toString()"
          class="flex items-center text-base leading-[19px]"
          role="listitem"
        >
          <CommonIcon
            v-if="getSelectedOptionIcon(selectedValue)"
            :name="getSelectedOptionIcon(selectedValue)"
            size="tiny"
            class="ltr:mr-1 rtl:ml-1"
          />{{
            getSelectedOptionLabel(selectedValue) ||
            i18n.t('%s (unknown)', getSelectedOptionValue(selectedValue))
          }}{{ idx === valueContainer.length - 1 ? '' : ',' }}
        </div>
      </div>
      <CommonIcon
        v-if="context.clearable && hasValue && !context.disabled"
        :aria-label="i18n.t('Clear Selection')"
        class="text-gray absolute -mt-5 shrink-0 ltr:right-2 rtl:left-2"
        name="close-small"
        size="base"
        role="button"
        tabindex="0"
        @click.stop="clearValue()"
        @keypress.space.prevent.stop="clearValue()"
      />
    </output>
  </div>
</template>
