<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, nextTick, ref, toRef } from 'vue'

import type { SelectValue } from '#shared/components/CommonSelect/types.ts'
import CommonTicketStateIndicator from '#shared/components/CommonTicketStateIndicator/CommonTicketStateIndicator.vue'
import useValue from '#shared/components/Form/composables/useValue.ts'
import type {
  FlatSelectOption,
  TreeSelectContext,
  TreeSelectOption,
} from '#shared/components/Form/fields/FieldTreeSelect/types.ts'
import useSelectOptions from '#shared/composables/useSelectOptions.ts'
import useSelectPreselect from '#shared/composables/useSelectPreselect.ts'
import { useFormBlock } from '#shared/form/useFormBlock.ts'
import { i18n } from '#shared/i18n.ts'

import { useDialog } from '#mobile/composables/useDialog.ts'

interface Props {
  context: TreeSelectContext
}

const props = defineProps<Props>()
const contextReactive = toRef(props, 'context')

const {
  hasValue,
  valueContainer,
  clearValue: clearInternalValue,
} = useValue(contextReactive)

const currentPath = ref<FlatSelectOption[]>([])

const clearPath = () => {
  currentPath.value = []
}

const nameDialog = `field-tree-select-${props.context.id}`

const outputElement = ref<HTMLOutputElement>()
const focusOutputElement = () => {
  if (!props.context.disabled) {
    outputElement.value?.focus()
  }
}

const dialog = useDialog({
  name: nameDialog,
  prefetch: true,
  component: () => import('./FieldTreeSelectInputDialog.vue'),
  afterClose() {
    clearPath()
  },
})

const clearValue = () => {
  if (props.context.disabled) return
  clearInternalValue()
  focusOutputElement()
}

const flattenOptions = (
  options: TreeSelectOption[],
  parents: SelectValue[] = [],
): FlatSelectOption[] =>
  options &&
  options.reduce((flatOptions: FlatSelectOption[], { children, ...option }) => {
    flatOptions.push({
      ...option,
      parents,
      hasChildren: Boolean(children),
    })
    if (children)
      flatOptions.push(...flattenOptions(children, [...parents, option.value]))
    return flatOptions
  }, [])

const flatOptions = computed(() => flattenOptions(props.context.options))

const filterInput = ref(null)

const focusFirstTarget = (targetElements?: HTMLElement[]) => {
  if (!props.context.noFiltering) {
    const filterInputElement = filterInput.value as null | HTMLElement
    if (filterInputElement) filterInputElement.focus()
    return
  }

  if (!targetElements || !targetElements.length) return

  targetElements[0].focus()
}

const {
  hasStatusProperty,
  sortedOptions,
  optionValueLookup,
  getSelectedOptionIcon,
  getSelectedOptionLabel,
  getSelectedOptionStatus,
  getDialogFocusTargets,
  setupMissingOrDisabledOptionHandling,
} = useSelectOptions(flatOptions, toRef(props, 'context'))

const openModal = () => {
  return dialog.open({
    context: toRef(props, 'context'),
    name: nameDialog,
    currentPath,
    flatOptions,
    sortedOptions,
    onPush(option: FlatSelectOption) {
      currentPath.value.push(option)
    },
    onPop() {
      currentPath.value.pop()
    },
  })
}

const getSelectedOptionParents = (
  selectedValue: string | number,
): SelectValue[] =>
  (optionValueLookup.value[selectedValue] &&
    (optionValueLookup.value[selectedValue] as FlatSelectOption).parents) ||
  []

const getSelectedOptionFullPath = (selectedValue: string | number) =>
  getSelectedOptionParents(selectedValue)
    .map((parentValue) => `${getSelectedOptionLabel(parentValue)} \u203A `)
    .join('') +
  (getSelectedOptionLabel(selectedValue) ||
    i18n.t('%s (unknown)', selectedValue.toString()))

const toggleDialog = async (isVisible: boolean) => {
  if (props.context.disabled) return
  if (isVisible) {
    await openModal()
    nextTick(() => focusFirstTarget(getDialogFocusTargets(true)))
    return
  }

  await dialog.close()
}

const onInputClick = () => {
  if (dialog.isOpened.value || !props.context.options?.length) return
  toggleDialog(true)
}

useSelectPreselect(flatOptions, contextReactive)
useFormBlock(contextReactive, onInputClick)
setupMissingOrDisabledOptionHandling()
</script>

<template>
  <div
    :class="{
      [context.classes.input]: true,
      'ltr:pr-9 rtl:pl-9': context.clearable && hasValue && !context.disabled,
    }"
    class="flex h-auto rounded-none bg-transparent"
    data-test-id="field-treeselect"
  >
    <!-- https://www.w3.org/WAI/ARIA/apg/patterns/combobox/ -->
    <output
      :id="context.id"
      ref="outputElement"
      role="combobox"
      :name="context.node.name"
      class="formkit-disabled:pointer-events-none flex grow items-center focus:outline-none"
      tabindex="0"
      :aria-labelledby="`label-${context.id}`"
      :aria-disabled="context.disabled ? 'true' : undefined"
      v-bind="context.attrs"
      :data-multiple="context.multiple"
      aria-haspopup="dialog"
      aria-autocomplete="none"
      :aria-controls="`dialog-${nameDialog}`"
      :aria-owns="`dialog-${nameDialog}`"
      :aria-expanded="dialog.isOpened.value"
      @keyup.shift.down.prevent="toggleDialog(true)"
      @keyup.space.prevent="toggleDialog(true)"
      @blur="context.handlers.blur"
    >
      <div v-if="hasValue" class="flex grow flex-wrap gap-1" role="list">
        <template v-if="hasStatusProperty">
          <CommonTicketStateIndicator
            v-for="selectedValue in valueContainer"
            :key="selectedValue"
            :color-code="getSelectedOptionStatus(selectedValue)!"
            :label="getSelectedOptionFullPath(selectedValue)"
            :data-test-status="getSelectedOptionStatus(selectedValue)"
            role="listitem"
            pill
          />
        </template>
        <template v-else>
          <div
            v-for="(selectedValue, idx) in valueContainer"
            :key="selectedValue"
            class="flex items-center text-base leading-[19px]"
            role="listitem"
          >
            <CommonIcon
              v-if="getSelectedOptionIcon(selectedValue)"
              :name="getSelectedOptionIcon(selectedValue)"
              size="tiny"
              class="ltr:mr-1 rtl:ml-1"
            />
            {{ getSelectedOptionFullPath(selectedValue)
            }}{{ idx === valueContainer.length - 1 ? '' : ',' }}
          </div>
        </template>
      </div>
      <CommonIcon
        v-if="context.clearable && hasValue && !context.disabled"
        :label="__('Clear Selection')"
        class="text-gray absolute -mt-5 shrink-0 ltr:right-2 rtl:left-2"
        name="close-small"
        size="base"
        role="button"
        tabindex="0"
        @click.stop="clearValue"
        @keypress.space.prevent.stop="clearValue"
      />
    </output>
  </div>
</template>
