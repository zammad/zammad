<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, nextTick, ref, toRef } from 'vue'
import { i18n } from '@shared/i18n'
import { useDialog } from '@shared/composables/useDialog'
import CommonTicketStateIndicator from '@shared/components/CommonTicketStateIndicator/CommonTicketStateIndicator.vue'
import { useFormBlock } from '@mobile/form/useFormBlock'
import useValue from '../../composables/useValue'
import useSelectOptions from '../../composables/useSelectOptions'
import useSelectPreselect from '../../composables/useSelectPreselect'
import type { SelectValue } from '../FieldSelect'
import type {
  TreeSelectOption,
  FlatSelectOption,
  TreeSelectContext,
} from './types'

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
  setupMissingOptionHandling,
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

const getSelectedOptionParents = (selectedValue: string | number) =>
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
setupMissingOptionHandling()
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
    <output
      :id="context.id"
      ref="outputElement"
      :name="context.node.name"
      class="flex grow items-center focus:outline-none formkit-disabled:pointer-events-none"
      :aria-disabled="context.disabled"
      :aria-label="i18n.t('Select…')"
      :data-multiple="context.multiple"
      :tabindex="context.disabled ? '-1' : '0'"
      v-bind="{
        ...context.attrs,
        onBlur: undefined,
      }"
      @keypress.space.prevent="toggleDialog(true)"
      @blur="context.handlers.blur"
    >
      <div v-if="hasValue" class="flex grow flex-wrap gap-1" role="list">
        <template v-if="hasStatusProperty">
          <CommonTicketStateIndicator
            v-for="selectedValue in valueContainer"
            :key="selectedValue"
            :status="getSelectedOptionStatus(selectedValue)"
            :label="getSelectedOptionFullPath(selectedValue)"
            :data-test-status="getSelectedOptionStatus(selectedValue)"
            role="listitem"
            pill
          />
        </template>
        <template v-else>
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
            {{ getSelectedOptionFullPath(selectedValue) }}
          </div>
        </template>
      </div>
      <CommonIcon
        v-if="context.clearable && hasValue && !context.disabled"
        :aria-label="i18n.t('Clear Selection')"
        class="absolute -mt-5 shrink-0 text-gray ltr:right-2 rtl:left-2"
        name="mobile-close-small"
        size="base"
        role="button"
        tabindex="0"
        @click.stop="clearValue"
        @keypress.space.prevent.stop="clearValue"
      />
    </output>
  </div>
</template>
