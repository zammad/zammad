<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { markRaw, ref, toRef, watch } from 'vue'
import { i18n } from '@shared/i18n'
import { useDialog } from '@shared/composables/useDialog'
import type { ObjectLike } from '@shared/types/utils'
import { useFormBlock } from '@mobile/form/useFormBlock'
import useValue from '../../composables/useValue'
import useSelectOptions from '../../composables/useSelectOptions'
import type { FormFieldContext } from '../../types/field'
import type { AutoCompleteOption, AutoCompleteProps } from './types'

interface Props {
  context: FormFieldContext<AutoCompleteProps>
}

const props = defineProps<Props>()
const contextReactive = toRef(props, 'context')

const { hasValue, valueContainer, currentValue, clearValue } =
  useValue(contextReactive)

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

const { optionValueLookup, getSelectedOptionIcon, getSelectedOptionLabel } =
  useSelectOptions(localOptions, contextReactive)

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
      :name="context.node.name"
      class="flex grow items-center focus:outline-none formkit-disabled:pointer-events-none"
      :aria-disabled="context.disabled"
      :aria-label="i18n.t('Select…')"
      :tabindex="context.disabled ? '-1' : '0'"
      :data-multiple="context.multiple"
      v-bind="{
        ...context.attrs,
        onBlur: undefined,
      }"
      @keypress.space.prevent="toggleDialog(true)"
      @blur="context.handlers.blur"
    >
      <div v-if="hasValue" class="flex grow flex-wrap gap-1" role="list">
        <div
          v-for="selectedValue in valueContainer"
          :key="selectedValue"
          class="flex items-center text-base leading-[19px] after:content-[','] last:after:content-none"
          role="listitem"
        >
          <CommonIcon
            v-if="getSelectedOptionIcon(selectedValue)"
            :name="getSelectedOptionIcon(selectedValue)"
            size="tiny"
            class="mr-1"
          />
          {{
            getSelectedOptionLabel(selectedValue) ||
            i18n.t('%s (unknown)', selectedValue)
          }}
        </div>
      </div>
      <CommonIcon
        v-if="context.clearable && hasValue && !context.disabled"
        :aria-label="i18n.t('Clear Selection')"
        class="absolute -mt-5 shrink-0 text-gray ltr:right-2 rtl:left-2"
        name="mobile-close-small"
        size="base"
        role="button"
        tabindex="0"
        @click.stop="clearValue()"
        @keypress.space.prevent.stop="clearValue()"
      />
    </output>
  </div>
</template>
