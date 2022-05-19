<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, nextTick, ref, toRef, watch } from 'vue'
import { escapeRegExp } from 'lodash-es'
import { Dialog, TransitionRoot, TransitionChild } from '@headlessui/vue'
import { i18n } from '@shared/i18n'
import CommonTicketStateIndicator from '@shared/components/CommonTicketStateIndicator/CommonTicketStateIndicator.vue'
import useLocaleStore from '@shared/stores/locale'
import useValue from '../../composables/useValue'
import useSelectDialog from '../../composables/useSelectDialog'
import useSelectOptions from '../../composables/useSelectOptions'
import useSelectAutoselect from '../../composables/useSelectAutoselect'
import type { FormFieldContext } from '../../types/field'
import type { SelectOption, SelectOptionSorting } from '../FieldSelect'
import type { TreeSelectOption, FlatSelectOption } from './types'

interface Props {
  context: FormFieldContext<{
    autoselect?: boolean
    clearable?: boolean
    noFiltering?: boolean
    disabled?: boolean
    multiple?: boolean
    noOptionsLabelTranslation?: boolean
    options: TreeSelectOption[]
    sorting?: SelectOptionSorting
  }>
}

const props = defineProps<Props>()

const { hasValue, valueContainer, isCurrentValue, clearValue } = useValue(
  toRef(props, 'context'),
)

const { isOpen, setIsOpen } = useSelectDialog()

const currentPath = ref<FlatSelectOption[]>([])

const currentParent = computed(
  () => currentPath.value[currentPath.value.length - 1] ?? null,
)

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

const pushToPath = (option: FlatSelectOption) => {
  currentPath.value.push(option)
}

const popFromPath = () => {
  currentPath.value.pop()
}

const clearPath = () => {
  currentPath.value = []
}

const filter = ref('')

const clearFilter = () => {
  filter.value = ''
}

watch(toRef(props.context, 'noFiltering'), clearFilter)

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
  hasStatusProperty,
  optionValueLookup,
  sortedOptions,
  getSelectedOptionIcon,
  getSelectedOptionLabel,
  getSelectedOptionStatus,
  selectOption,
  getDialogFocusTargets,
  advanceDialogFocus,
} = useSelectOptions(
  flatOptions,
  toRef(props, 'context'),
  previousPageCallback,
  nextPageCallback,
)

const getSelectedOptionParents = (selectedValue: string | number) =>
  (optionValueLookup.value[selectedValue] &&
    (optionValueLookup.value[selectedValue] as FlatSelectOption).parents) ||
  []

const getSelectedOptionFullPath = (selectedValue: string | number) =>
  getSelectedOptionParents(selectedValue)
    .map((parentValue) => `${getSelectedOptionLabel(parentValue)} \u203A `)
    .join('') +
  (getSelectedOptionLabel(selectedValue) || selectedValue.toString())

const goToPreviousPage = () => {
  previousPageCallback(undefined, getDialogFocusTargets)
}

const goToNextPage = (option: FlatSelectOption) => {
  nextPageCallback(option, getDialogFocusTargets)
}

const toggleDialog = (isVisible: boolean) => {
  setIsOpen(isVisible)

  if (isVisible) {
    nextTick(() => focusFirstTarget(getDialogFocusTargets(true)))
    return
  }

  clearPath()
  clearFilter()
}

const select = (option: FlatSelectOption) => {
  selectOption(option)
  if (!props.context.multiple) toggleDialog(false)
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
  return options.filter((option) => filterRegex.test(deaccent(option.label)))
})

useSelectAutoselect(flatOptions, toRef(props, 'context'))

const locale = useLocaleStore()
</script>

<template>
  <div
    :class="{
      [context.classes.input]: true,
    }"
    class="flex h-auto min-h-[3.5rem] rounded-none bg-transparent focus-within:bg-blue-highlight focus-within:pt-0 formkit-populated:pt-0"
    data-test-id="field-treeselect"
  >
    <output
      :id="context.id"
      :name="context.node.name"
      class="flex grow cursor-pointer items-center px-3 focus:outline-none formkit-disabled:pointer-events-none"
      :aria-disabled="context.disabled"
      :aria-label="i18n.t('Select…')"
      :tabindex="context.disabled ? '-1' : '0'"
      v-bind="context.attrs"
      role="list"
      @click="toggleDialog(true)"
      @keypress.space="toggleDialog(true)"
      @blur="context.handlers.blur"
    >
      <div class="flex grow translate-y-2 flex-wrap gap-1">
        <template v-if="hasValue && hasStatusProperty">
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
        <template v-else-if="hasValue">
          <div
            v-for="selectedValue in valueContainer"
            :key="selectedValue"
            class="flex items-center text-base leading-[19px] after:content-[','] last:after:content-none"
            role="listitem"
          >
            <CommonIcon
              v-if="getSelectedOptionIcon(selectedValue)"
              :name="getSelectedOptionIcon(selectedValue)"
              :fixed-size="{ width: 12, height: 12 }"
              class="mr-1"
            />
            {{ getSelectedOptionFullPath(selectedValue) }}
          </div>
        </template>
      </div>
      <CommonIcon
        v-if="context.clearable && hasValue && !context.disabled"
        :aria-label="i18n.t('Clear Selection')"
        :fixed-size="{ width: 16, height: 16 }"
        class="mr-2 shrink-0"
        name="close-small"
        role="button"
        tabindex="0"
        @click.stop="clearValue"
        @keypress.space.prevent.stop="clearValue"
      />
      <CommonIcon
        :fixed-size="{ width: 24, height: 24 }"
        class="shrink-0"
        :name="`chevron-${locale.localeData?.dir === 'rtl' ? 'left' : 'right'}`"
        decorative
      />
    </output>
    <TransitionRoot :show="isOpen" as="template" appear>
      <Dialog
        class="fixed inset-0 z-10 flex overflow-y-auto"
        role="dialog"
        @close="toggleDialog(false)"
      >
        <TransitionChild
          class="h-full grow"
          enter="duration-300 ease-out"
          enter-from="opacity-0 translate-y-3/4"
          enter-to="opacity-100 translate-y-0"
          leave="duration-200 ease-in"
          leave-from="opacity-100 translate-y-0"
          leave-to="opacity-0 translate-y-3/4"
        >
          <div ref="dialog" class="flex h-full grow flex-col bg-black">
            <div class="mx-4 h-2.5 shrink-0 rounded-t-xl bg-gray-150/40" />
            <div
              class="relative flex h-16 shrink-0 items-center justify-center rounded-t-xl bg-gray-600/80"
            >
              <div
                class="grow text-center text-base font-semibold leading-[19px] text-white"
              >
                {{ i18n.t(context.label) }}
              </div>
              <div
                class="absolute top-0 right-0 bottom-0 flex items-center pr-4"
              >
                <div
                  class="grow cursor-pointer text-blue"
                  tabindex="0"
                  role="button"
                  @click="toggleDialog(false)"
                  @keypress.space="toggleDialog(false)"
                  @keydown="advanceDialogFocus"
                >
                  {{ i18n.t('Done') }}
                </div>
              </div>
            </div>
            <div
              class="flex grow flex-col items-start overflow-y-auto bg-black text-white"
            >
              <div
                v-if="!context.noFiltering"
                class="relative flex items-center self-stretch p-4"
              >
                <CommonIcon
                  :fixed-size="{ width: 24, height: 24 }"
                  class="absolute left-6 shrink-0 text-gray"
                  name="search"
                  decorative
                />
                <input
                  ref="filterInput"
                  v-model="filter"
                  :placeholder="i18n.t('Search')"
                  class="h-12 grow rounded-xl bg-gray-500 px-9 placeholder:text-gray focus:border-white focus:outline-none focus:ring-0"
                  type="text"
                  role="searchbox"
                />
                <CommonIcon
                  v-if="filter.length"
                  :aria-label="i18n.t('Clear Search')"
                  :fixed-size="{ width: 24, height: 24 }"
                  class="absolute right-6 shrink-0 text-gray"
                  name="close-small"
                  @click.stop="clearFilter"
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
                :class="{
                  'border-t border-white/30': currentPath.length,
                }"
                class="flex grow flex-col items-start self-stretch overflow-y-auto"
                role="listbox"
              >
                <div
                  v-for="(option, index) in filter
                    ? filteredOptions
                    : currentOptions"
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
                      'left-4': !context.multiple,
                      'left-14': context.multiple,
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
                    :name="
                      isCurrentValue(option.value)
                        ? 'checked-yes'
                        : 'checked-no'
                    "
                    class="mr-3 text-white/50"
                  />
                  <CommonTicketStateIndicator
                    v-if="option.status"
                    :status="option.status"
                    :label="option.label"
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
                  {{ i18n.t('No results found') }}
                </div>
              </div>
            </div>
          </div>
        </TransitionChild>
      </Dialog>
    </TransitionRoot>
  </div>
</template>

<style lang="scss">
.field-treeselect {
  &.floating-input:focus-within:not([data-populated]) {
    label {
      @apply translate-y-0 translate-x-0 scale-100 opacity-100;
    }
  }

  .formkit-label {
    @apply py-4;
  }
}
</style>
