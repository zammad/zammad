<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonInputSearch from '@shared/components/CommonInputSearch/CommonInputSearch.vue'
import CommonDialog from '@mobile/components/CommonDialog/CommonDialog.vue'
import CommonTicketStateIndicator from '@shared/components/CommonTicketStateIndicator/CommonTicketStateIndicator.vue'
import { closeDialog } from '@shared/composables/useDialog'
import { computed, nextTick, onMounted, ref, toRef, watch } from 'vue'
import { escapeRegExp } from 'lodash-es'
import useSelectOptions from '../../composables/useSelectOptions'
import type { TreeSelectContext, TreeSelectOption } from './types'
import { FlatSelectOption } from './types'
import type { SelectOption } from '../FieldSelect'
import useValue from '../../composables/useValue'

const props = defineProps<{
  context: TreeSelectContext
  name: string
  currentPath: FlatSelectOption[]
}>()

const { isCurrentValue } = useValue(toRef(props, 'context'))

const emit = defineEmits<{
  (e: 'push', option: FlatSelectOption): void
  (e: 'pop'): void
}>()

const currentParent = computed(
  () => props.currentPath[props.currentPath.length - 1] ?? null,
)

const filter = ref('')
const filterInput = ref<HTMLInputElement>()

const clearFilter = () => {
  filter.value = ''
}

const close = () => {
  closeDialog(props.name)
  clearFilter()
}

const pushToPath = (option: FlatSelectOption) => {
  emit('push', option)
}

const popFromPath = () => {
  emit('pop')
}

const flattenOptions = (
  options: TreeSelectOption[],
  parents: (string | number)[] = [],
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
const contextReactive = toRef(props, 'context')

watch(() => contextReactive.value.noFiltering, clearFilter)

const focusFirstTarget = (targetElements?: HTMLElement[]) => {
  if (!props.context.noFiltering) {
    filterInput.value?.focus()
    return
  }

  if (!targetElements || !targetElements.length) return

  targetElements[0].focus()
}

const previousPageCallback = (
  option?: SelectOption | FlatSelectOption,
  getDialogFocusTargets?: (optionsOnly?: boolean) => HTMLElement[],
) => {
  popFromPath()
  clearFilter()
  nextTick(() =>
    focusFirstTarget(getDialogFocusTargets && getDialogFocusTargets(true)),
  )
}

const nextPageCallback = (
  option?: SelectOption | FlatSelectOption,
  getDialogFocusTargets?: (optionsOnly?: boolean) => HTMLElement[],
) => {
  if (option && (option as FlatSelectOption).hasChildren) {
    pushToPath(option as FlatSelectOption)
    nextTick(() =>
      focusFirstTarget(getDialogFocusTargets && getDialogFocusTargets(true)),
    )
  }
}

const {
  dialog,
  sortedOptions,
  getSelectedOptionLabel,
  selectOption,
  getDialogFocusTargets,
  advanceDialogFocus,
} = useSelectOptions(
  flatOptions,
  contextReactive,
  previousPageCallback,
  nextPageCallback,
)

const deaccent = (s: string) =>
  s.normalize('NFD').replace(/[\u0300-\u036f]/g, '')

const filteredOptions = computed(() => {
  // In case we are not currently filtering for a parent, search across all options.
  let options = sortedOptions.value

  // Otherwise, search across options which are children of the current parent.
  if (currentParent.value)
    options = sortedOptions.value.filter((option) =>
      (option as FlatSelectOption).parents.includes(currentParent.value?.value),
    )

  // Trim and de-accent search keywords and compile them as a case-insensitive regex.
  //   Make sure to escape special regex characters!
  const filterRegex = new RegExp(
    escapeRegExp(deaccent(filter.value.trim())),
    'i',
  )

  // Search across options via their de-accented labels.
  return options.filter((option) =>
    filterRegex.test(deaccent(option.label || String(option.value))),
  )
})

const select = (option: FlatSelectOption) => {
  selectOption(option)
  if (!props.context.multiple) close()
}

const currentOptions = computed(() => {
  // In case we are not currently filtering for a parent, return only top-level options.
  if (!currentParent.value)
    return sortedOptions.value.filter(
      (option) => !(option as FlatSelectOption).parents.length,
    )

  // Otherwise, return all options which are children of the current parent.
  return sortedOptions.value.filter(
    (option) =>
      (option as FlatSelectOption).parents.length &&
      (option as FlatSelectOption).parents[
        (option as FlatSelectOption).parents.length - 1
      ] === currentParent.value?.value,
  )
})

const goToPreviousPage = () => {
  previousPageCallback(undefined, getDialogFocusTargets)
}

const goToNextPage = (option: FlatSelectOption) => {
  nextPageCallback(option, getDialogFocusTargets)
}

onMounted(() => {
  filterInput.value?.focus()
})
</script>

<template>
  <CommonDialog
    :name="name"
    :label="$t(context.label)"
    :listeners="{ done: { onKeydown: advanceDialogFocus } }"
    @close="close"
  >
    <div class="w-full p-4">
      <CommonInputSearch
        v-if="!context.noFiltering"
        ref="filterInput"
        v-model="filter"
      />
    </div>
    <div
      v-if="currentPath.length"
      :class="{
        'px-6': !context.noFiltering,
      }"
      class="flex h-[58px] cursor-pointer items-center self-stretch py-5 px-4 text-base leading-[19px] text-white focus:bg-blue-highlight focus:outline-none"
      tabindex="0"
      role="button"
      @click="goToPreviousPage()"
      @keypress.space="goToPreviousPage()"
      @keydown="advanceDialogFocus"
    >
      <CommonIcon
        :fixed-size="{ width: 24, height: 24 }"
        class="mr-3"
        name="chevron-left"
      />
      <span class="grow font-semibold text-white/80">
        {{ currentParent.label || currentParent.value }}
      </span>
    </div>
    <div
      ref="dialog"
      :class="{
        'border-t border-white/30': currentPath.length,
      }"
      class="flex grow flex-col items-start self-stretch overflow-y-auto"
      role="listbox"
    >
      <div
        v-for="(option, index) in filter ? filteredOptions : currentOptions"
        :key="option.value"
        :class="{
          'px-6': !context.noFiltering,
          'pointer-events-none': option.disabled,
        }"
        :tabindex="option.disabled ? '-1' : '0'"
        :aria-selected="isCurrentValue(option.value)"
        class="relative flex h-[58px] cursor-pointer items-center self-stretch py-5 px-4 text-base leading-[19px] text-white focus:bg-blue-highlight focus:outline-none"
        role="option"
        @click="select(option as FlatSelectOption)"
        @keypress.space="select(option as FlatSelectOption)"
        @keydown="advanceDialogFocus($event, option)"
      >
        <div
          v-if="index !== 0"
          :class="{
            'left-4': !context.multiple && !option.icon && !(option as FlatSelectOption).status,
            'left-[50px]': !context.multiple && option.icon && !(option as FlatSelectOption).status,
            'left-[58px]': !context.multiple && !option.icon && (option as FlatSelectOption).status,
            'left-[60px]': context.multiple && !option.icon && !(option as FlatSelectOption).status,
            'left-[88px]': context.multiple && option.icon && !(option as FlatSelectOption).status,
            'left-[94px]': context.multiple && !option.icon && (option as FlatSelectOption).status,
          }"
          class="absolute right-4 top-0 h-0 border-t border-white/10"
        />
        <CommonIcon
          v-if="context.multiple"
          :class="{
            '!text-white': isCurrentValue(option.value),
            'opacity-30': option.disabled,
          }"
          :fixed-size="{ width: 24, height: 24 }"
          :name="isCurrentValue(option.value) ? 'checked-yes' : 'checked-no'"
          class="mr-3 text-white/50"
        />
        <CommonTicketStateIndicator
          v-if="(option as FlatSelectOption).status"
          :status="(option as FlatSelectOption).status"
          :label="option.label || String(option.value)"
          :class="{
            'opacity-30': option.disabled,
          }"
          class="mr-[11px]"
        />
        <CommonIcon
          v-else-if="option.icon"
          :name="option.icon"
          :fixed-size="{ width: 16, height: 16 }"
          :class="{
            '!text-white': isCurrentValue(option.value),
            'opacity-30': option.disabled,
          }"
          class="mr-[11px] text-white/80"
        />
        <span
          :class="{
            'font-semibold !text-white': isCurrentValue(option.value),
            'opacity-30': option.disabled,
          }"
          class="grow text-white/80"
        >
          {{ option.label || option.value }}
          <template v-if="filter">
            <span
              v-for="parentValue in (option as FlatSelectOption).parents"
              :key="parentValue"
              class="opacity-50"
            >
              —
              {{ getSelectedOptionLabel(parentValue) || parentValue }}
            </span>
          </template>
        </span>
        <CommonIcon
          v-if="!context.multiple && isCurrentValue(option.value)"
          :class="{
            'opacity-30': option.disabled,
            'mr-3': (option as FlatSelectOption).hasChildren,
        }"
          :fixed-size="{ width: 16, height: 16 }"
          name="check"
        />
        <CommonIcon
          v-if="(option as FlatSelectOption).hasChildren && !filter"
          class="pointer-events-auto"
          :fixed-size="{ width: 24, height: 24 }"
          name="chevron-right"
          role="link"
          @click.stop="goToNextPage(option as FlatSelectOption)"
        />
      </div>
      <div
        v-if="filter && !filteredOptions.length"
        class="relative flex h-[58px] items-center justify-center self-stretch py-5 px-4 text-base leading-[19px] text-white/50"
        role="alert"
      >
        {{ $t('No results found') }}
      </div>
    </div>
  </CommonDialog>
</template>
