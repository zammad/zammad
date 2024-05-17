<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useElementBounding, useWindowSize } from '@vueuse/core'
import { escapeRegExp } from 'lodash-es'
import { computed, nextTick, ref, toRef, watch } from 'vue'

import useValue from '#shared/components/Form/composables/useValue.ts'
import type {
  FlatSelectOption,
  TreeSelectContext,
} from '#shared/components/Form/fields/FieldTreeSelect/types.ts'
import useSelectOptions from '#shared/composables/useSelectOptions.ts'
import useSelectPreselect from '#shared/composables/useSelectPreselect.ts'
import { useTrapTab } from '#shared/composables/useTrapTab.ts'
import { useFormBlock } from '#shared/form/useFormBlock.ts'
import { i18n } from '#shared/i18n.ts'

import CommonInputSearch from '#desktop/components/CommonInputSearch/CommonInputSearch.vue'
import type { CommonSelectInstance } from '#desktop/components/CommonSelect/types.ts'

import FieldTreeSelectInputDropdown from './FieldTreeSelectInputDropdown.vue'
import useFlatSelectOptions from './useFlatSelectOptions.ts'

interface Props {
  context: TreeSelectContext & {
    alternativeBackground?: boolean
  }
}

const props = defineProps<Props>()
const contextReactive = toRef(props, 'context')

const {
  hasValue,
  valueContainer,
  currentValue,
  clearValue: clearInternalValue,
} = useValue(contextReactive)

const { flatOptions } = useFlatSelectOptions(toRef(props.context, 'options'))

const {
  sortedOptions,
  optionValueLookup,
  selectOption,
  getSelectedOption,
  getSelectedOptionIcon,
  getSelectedOptionLabel,
  getSelectedOptionFullPath,
  setupMissingOrDisabledOptionHandling,
} = useSelectOptions<FlatSelectOption[]>(flatOptions, toRef(props, 'context'))

const currentPath = ref<FlatSelectOption[]>([])

const clearPath = () => {
  currentPath.value = []
}

const currentParent = computed<FlatSelectOption>(
  () => currentPath.value[currentPath.value.length - 1] ?? null,
)

const input = ref<HTMLDivElement>()
const outputElement = ref<HTMLOutputElement>()
const filter = ref('')
const filterInput = ref<HTMLInputElement>()
const select = ref<CommonSelectInstance>()

const { activateTabTrap, deactivateTabTrap } = useTrapTab(input, true)

const clearFilter = () => {
  filter.value = ''
}

watch(() => contextReactive.value.noFiltering, clearFilter)

const deaccent = (s: string) =>
  s.normalize('NFD').replace(/[\u0300-\u036f]/g, '')

const filteredOptions = computed(() => {
  // In case we are not currently filtering for a parent, search across all options.
  let options = sortedOptions.value

  // Otherwise, search across options which are children of the current parent.
  if (currentParent.value)
    options = sortedOptions.value.filter((option) =>
      option.parents.includes(currentParent.value?.value),
    )

  // Trim and de-accent search keywords and compile them as a case-insensitive regex.
  //   Make sure to escape special regex characters!
  const filterRegex = new RegExp(
    escapeRegExp(deaccent(filter.value.trim())),
    'i',
  )

  return options
    .map(
      (option) =>
        ({
          ...option,

          // Match options via their de-accented labels.
          match: filterRegex.exec(
            deaccent(option.label || String(option.value)),
          ),
        }) as FlatSelectOption,
    )
    .filter((option) => option.match)
})

const suggestedOptionLabel = computed(() => {
  if (!filter.value || !filteredOptions.value.length) return undefined

  const exactMatches = filteredOptions.value.filter(
    (option) =>
      (getSelectedOptionLabel(option.value) || option.value.toString())
        .toLowerCase()
        .indexOf(filter.value.toLowerCase()) === 0 &&
      (getSelectedOptionLabel(option.value) || option.value.toString()).length >
        filter.value.length,
  )

  if (!exactMatches.length) return undefined

  return getSelectedOptionLabel(exactMatches[0].value)
})

const currentOptions = computed(() => {
  // In case we are not currently filtering for a parent, return only top-level options.
  if (!currentParent.value)
    return sortedOptions.value.filter((option) => !option.parents?.length)

  // Otherwise, return all options which are children of the current parent.
  return sortedOptions.value.filter(
    (option) =>
      option.parents.length &&
      option.parents[option.parents.length - 1] === currentParent.value?.value,
  )
})

const focusOutputElement = () => {
  if (!props.context.disabled) {
    outputElement.value?.focus()
  }
}

const clearValue = () => {
  if (props.context.disabled) return
  clearInternalValue()
  focusOutputElement()
}

const inputElementBounds = useElementBounding(input)
const windowSize = useWindowSize()

const isBelowHalfScreen = computed(() => {
  return inputElementBounds.y.value > windowSize.height.value / 2
})

const openSelectDropdown = () => {
  if (select.value?.isOpen || props.context.disabled) return

  select.value?.openDropdown(inputElementBounds, windowSize.height)

  requestAnimationFrame(() => {
    activateTabTrap()
    if (props.context.noFiltering) outputElement.value?.focus()
    else filterInput.value?.focus()
  })
}

const openOrMoveFocusToDropdown = (lastOption = false) => {
  if (!select.value?.isOpen) {
    openSelectDropdown()
    return
  }

  deactivateTabTrap()

  nextTick(() => {
    requestAnimationFrame(() => {
      select.value?.moveFocusToDropdown(lastOption)
    })
  })
}

const onCloseDropdown = () => {
  clearFilter()
  clearPath()
  deactivateTabTrap()
}

const onPathPush = (option: FlatSelectOption) => {
  currentPath.value.push(option)
}

const onPathPop = () => {
  currentPath.value.pop()
}

useFormBlock(contextReactive, openSelectDropdown)

useSelectPreselect(flatOptions, contextReactive)
setupMissingOrDisabledOptionHandling()
</script>

<template>
  <div
    ref="input"
    class="flex h-auto min-h-10 hover:outline hover:outline-1 hover:outline-offset-1 hover:outline-blue-600 has-[output:focus,input:focus]:outline has-[output:focus,input:focus]:outline-1 has-[output:focus,input:focus]:outline-offset-1 has-[output:focus,input:focus]:outline-blue-800 dark:hover:outline-blue-900 dark:has-[output:focus,input:focus]:outline-blue-800"
    :class="[
      context.classes.input,
      {
        'rounded-lg': !select?.isOpen,
        'rounded-t-lg': select?.isOpen && !isBelowHalfScreen,
        'rounded-b-lg': select?.isOpen && isBelowHalfScreen,
        'bg-blue-200 dark:bg-gray-700': !context.alternativeBackground,
        'bg-white dark:bg-gray-500': context.alternativeBackground,
      },
    ]"
    data-test-id="field-treeselect"
  >
    <FieldTreeSelectInputDropdown
      ref="select"
      #default="{ state: expanded, close: closeDropdown }"
      :model-value="currentValue"
      :options="filteredOptions"
      :multiple="context.multiple"
      :owner="context.id"
      :current-path="currentPath"
      :filter="filter"
      :flat-options="flatOptions"
      :current-options="currentOptions"
      :option-value-lookup="optionValueLookup"
      no-options-label-translation
      no-close
      passive
      @clear-filter="clearFilter"
      @close="onCloseDropdown"
      @push="onPathPush"
      @pop="onPathPop"
      @select="selectOption"
    >
      <!-- https://www.w3.org/WAI/ARIA/apg/patterns/combobox/ -->
      <output
        :id="context.id"
        ref="outputElement"
        role="combobox"
        :name="context.node.name"
        class="flex grow items-center gap-2.5 px-2.5 py-2 text-black focus:outline-none dark:text-white"
        tabindex="0"
        :aria-labelledby="`label-${context.id}`"
        :aria-disabled="context.disabled ? 'true' : undefined"
        v-bind="context.attrs"
        :data-multiple="context.multiple"
        aria-autocomplete="none"
        aria-controls="field-tree-select-input-dropdown"
        aria-owns="field-tree-select-input-dropdown"
        aria-haspopup="menu"
        :aria-expanded="expanded"
        :aria-describedby="context.describedBy"
        @keydown.escape.prevent="closeDropdown()"
        @keypress.enter.prevent="openSelectDropdown()"
        @keydown.down.prevent="openOrMoveFocusToDropdown()"
        @keydown.up.prevent="openOrMoveFocusToDropdown(true)"
        @keypress.space.prevent="openSelectDropdown()"
        @blur="context.handlers.blur"
      >
        <div
          v-if="hasValue && context.multiple"
          class="flex flex-wrap gap-1.5"
          role="list"
        >
          <div
            v-for="selectedValue in valueContainer"
            :key="selectedValue"
            class="flex items-center gap-1.5"
            role="listitem"
          >
            <div
              class="inline-flex cursor-default items-center gap-1 rounded px-1.5 py-0.5 text-xs text-black dark:text-white"
              :class="{
                'bg-white dark:bg-gray-200': !context.alternativeBackground,
                'bg-neutral-100 dark:bg-gray-200':
                  context.alternativeBackground,
              }"
            >
              <CommonIcon
                v-if="getSelectedOptionIcon(selectedValue)"
                :name="getSelectedOptionIcon(selectedValue)"
                class="shrink-0 fill-gray-100 dark:fill-neutral-400"
                size="xs"
                decorative
              />
              <span
                class="line-clamp-3 whitespace-pre-wrap break-words"
                :title="getSelectedOptionFullPath(selectedValue)"
              >
                {{ getSelectedOptionFullPath(selectedValue) }}
              </span>
              <CommonIcon
                :aria-label="i18n.t('Unselect Option')"
                class="shrink-0 fill-stone-200 hover:fill-black focus:outline-none focus-visible:rounded-sm focus-visible:outline focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800 dark:fill-neutral-500 dark:hover:fill-white"
                name="x-lg"
                size="xs"
                role="button"
                tabindex="0"
                @click.stop="selectOption(getSelectedOption(selectedValue))"
                @keypress.enter.prevent.stop="
                  selectOption(getSelectedOption(selectedValue))
                "
                @keypress.space.prevent.stop="
                  selectOption(getSelectedOption(selectedValue))
                "
              />
            </div>
          </div>
        </div>
        <CommonInputSearch
          v-if="expanded && !context.noFiltering"
          ref="filterInput"
          v-model="filter"
          :suggestion="suggestedOptionLabel"
          :alternative-background="context.alternativeBackground"
          @keypress.space.stop
        />
        <div v-else class="flex grow flex-wrap gap-1" role="list">
          <div
            v-if="hasValue && !context.multiple"
            class="flex items-center gap-1.5 text-sm"
            role="listitem"
          >
            <CommonIcon
              v-if="getSelectedOptionIcon(currentValue)"
              :name="getSelectedOptionIcon(currentValue)"
              class="shrink-0 fill-gray-100 dark:fill-neutral-400"
              size="tiny"
              decorative
            />
            <span
              class="line-clamp-3 whitespace-pre-wrap break-words"
              :title="getSelectedOptionFullPath(currentValue)"
            >
              {{ getSelectedOptionFullPath(currentValue) }}
            </span>
          </div>
        </div>
        <CommonIcon
          v-if="context.clearable && hasValue && !context.disabled"
          :aria-label="i18n.t('Clear Selection')"
          class="shrink-0 fill-stone-200 hover:fill-black focus:outline-none focus-visible:rounded-sm focus-visible:outline focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800 dark:fill-neutral-500 dark:hover:fill-white"
          name="x-lg"
          size="xs"
          role="button"
          tabindex="0"
          @click.stop="clearValue()"
          @keypress.enter.prevent.stop="clearValue()"
          @keypress.space.prevent.stop="clearValue()"
        />
        <CommonIcon
          class="shrink-0 fill-stone-200 dark:fill-neutral-500"
          name="chevron-down"
          size="xs"
          decorative
        />
      </output>
    </FieldTreeSelectInputDropdown>
  </div>
</template>
