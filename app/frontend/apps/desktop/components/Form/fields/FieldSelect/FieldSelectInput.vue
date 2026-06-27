<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import {
  useDebounceFn,
  useElementBounding,
  useElementVisibility,
  useWindowSize,
} from '@vueuse/core'
import { escapeRegExp } from 'lodash-es'
import { useTemplateRef, computed, nextTick, onMounted, ref, toRef, watch } from 'vue'

import type { SelectOption } from '#shared/components/CommonSelect/types.ts'
import useValue from '#shared/components/Form/composables/useValue.ts'
import type { SelectContext } from '#shared/components/Form/fields/FieldSelect/types.ts'
import useSelectOptions from '#shared/composables/useSelectOptions.ts'
import useSelectPreselect from '#shared/composables/useSelectPreselect.ts'
import { useTrapTab } from '#shared/composables/useTrapTab.ts'
import { useFormBlock } from '#shared/form/useFormBlock.ts'
import { i18n } from '#shared/i18n.ts'
import stopEvent from '#shared/utils/events.ts'

import CommonInputSearch from '#desktop/components/CommonInputSearch/CommonInputSearch.vue'
import CommonSelect from '#desktop/components/CommonSelect/CommonSelect.vue'

interface Props {
  context: SelectContext & {
    alternativeBackground?: boolean
  }
}

const props = defineProps<Props>()

const contextReactive = toRef(props, 'context')

const { hasValue, valueContainer, currentValue, clearValue } = useValue(contextReactive)

const {
  sortedOptions,
  selectOption,
  getSelectedOption,
  getSelectedOptionIcon,
  getSelectedOptionLabel,
  setupMissingOrDisabledOptionHandling,
} = useSelectOptions(toRef(props.context, 'options'), contextReactive)

const inputElement = useTemplateRef('input')
const outputElement = useTemplateRef('output')
const filterInputElement = useTemplateRef('filter-input')
const selectInstance = useTemplateRef('select')

const filter = ref('')

const { activateTabTrap, deactivateTabTrap } = useTrapTab(inputElement, true)

const clearFilter = () => {
  filter.value = ''
}

watch(() => contextReactive.value.noFiltering, clearFilter)

const deaccent = (s: string) => s.normalize('NFD').replace(/[\u0300-\u036f]/g, '')

const filteredOptions = computed(() => {
  // Trim and de-accent search keywords and compile them as a case-insensitive regex.
  //   Make sure to escape special regex characters!
  const filterRegex = new RegExp(escapeRegExp(deaccent(filter.value.trim())), 'i')

  return sortedOptions.value
    .map(
      (option) =>
        ({
          ...option,

          // Match options via their de-accented labels.
          match: filterRegex.exec(deaccent(option.label || String(option.value))),
        }) as SelectOption,
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

const inputElementBounds = useElementBounding(inputElement)
const isInputVisible = !!VITE_TEST_MODE || useElementVisibility(inputElement)
const windowSize = useWindowSize()

const isBelowHalfScreen = computed(() => {
  return inputElementBounds.y.value > windowSize.height.value / 2
})

const openSelectDropdown = () => {
  if (props.context.disabled) return
  if (!inputElement.value) return

  selectInstance.value?.openDropdown(inputElementBounds, windowSize.height)

  requestAnimationFrame(() => {
    activateTabTrap()
    if (props.context.noFiltering) outputElement.value?.focus()
    else filterInputElement.value?.focus()
  })
}

onMounted(() => {
  if (props.context.autoOpenDropdown) openSelectDropdown()
})

const openOrMoveFocusToDropdown = (lastOption = false) => {
  if (!selectInstance.value?.isOpen) {
    return openSelectDropdown()
  }

  deactivateTabTrap()

  nextTick(() => {
    requestAnimationFrame(() => {
      selectInstance.value?.moveFocusToDropdown(lastOption)
    })
  })
}

const onCloseDropdown = () => {
  clearFilter()
  deactivateTabTrap()
}

const foldDropdown = (event: MouseEvent) => {
  if ((event?.target as HTMLElement)?.tagName !== 'INPUT' && selectInstance.value) {
    selectInstance.value.closeDropdown()

    return onCloseDropdown()
  }
}

const handleToggleDropdown = (event: MouseEvent) => {
  if (selectInstance.value?.isOpen) return foldDropdown(event)
  openSelectDropdown()
}

const handleCloseDropdown = (
  event: KeyboardEvent,
  expanded: boolean,
  closeDropdown: () => void,
) => {
  if (expanded) {
    stopEvent(event)
    closeDropdown()
  }
}

useFormBlock(
  contextReactive,
  useDebounceFn((event) => {
    if (selectInstance.value?.isOpen) foldDropdown(event)
    openSelectDropdown()
  }, 500),
)

useSelectPreselect(sortedOptions, contextReactive)
setupMissingOrDisabledOptionHandling()
</script>

<template>
  <div
    ref="input"
    class="flex h-auto min-h-10 bg-blue-200 hover:outline-1 hover:-outline-offset-1 hover:outline-blue-600 has-[output:focus,input:focus]:outline-1 has-[output:focus,input:focus]:-outline-offset-1 has-[output:focus,input:focus]:outline-blue-800 dark:bg-gray-700 dark:hover:outline-blue-900 dark:has-[output:focus,input:focus]:outline-blue-800 formkit-alternative-background:bg-neutral-50 dark:formkit-alternative-background:bg-gray-500"
    :class="[
      context.classes.input,
      {
        'rounded-lg': !selectInstance?.isOpen,
        'rounded-t-lg': selectInstance?.isOpen && !isBelowHalfScreen,
        'rounded-b-lg': selectInstance?.isOpen && isBelowHalfScreen,
      },
    ]"
    data-test-id="field-select"
  >
    <CommonSelect
      ref="select"
      #default="{ state: expanded, close: closeDropdown }"
      :model-value="currentValue"
      :options="filteredOptions"
      :multiple="context.multiple"
      :owner="context.id"
      :filter="filter"
      :is-target-visible="isInputVisible"
      no-options-label-translation
      no-close
      passive
      @select="selectOption"
      @close="onCloseDropdown"
    >
      <!-- eslint-disable vuejs-accessibility/interactive-supports-focus-->
      <output
        :id="context.id"
        ref="output"
        role="combobox"
        aria-controls="common-select"
        aria-owns="common-select"
        aria-haspopup="menu"
        :aria-expanded="expanded"
        :name="context.node.name"
        class="flex grow items-center gap-2.5 px-2.5 py-2 text-black focus:outline-hidden dark:text-white formkit-disabled:pointer-events-none"
        :aria-labelledby="`label-${context.id}`"
        :aria-disabled="context.disabled"
        :data-multiple="context.multiple"
        :aria-describedby="context.describedBy"
        :tabindex="expanded && !context.noFiltering ? '-1' : '0'"
        v-bind="context.attrs"
        @keydown.escape="handleCloseDropdown($event, expanded, closeDropdown)"
        @keypress.enter.prevent="openSelectDropdown()"
        @keydown.down.prevent="openOrMoveFocusToDropdown()"
        @keydown.up.prevent="openOrMoveFocusToDropdown(true)"
        @keypress.space.prevent="openSelectDropdown()"
        @blur="context.handlers.blur"
        @click.stop="handleToggleDropdown"
      >
        <div
          v-if="hasValue && context.multiple"
          class="select-scroll-shadows flex flex-wrap gap-1.5 overflow-y-auto outline-hidden"
          :class="{
            'select-scroll-shadows--base': !context.alternativeBackground,
            'select-scroll-shadows--alt': context.alternativeBackground,
            'max-w-1/2 shrink-0': expanded,
          }"
          role="list"
        >
          <div
            v-for="selectedValue in valueContainer"
            :key="selectedValue"
            class="flex items-center gap-1.5"
            role="listitem"
          >
            <div
              class="inline-flex items-center gap-1 rounded bg-white px-1.5 py-0.5 text-xs text-black dark:bg-gray-200 dark:text-white formkit-alternative-background:bg-neutral-100 dark:formkit-alternative-background:bg-gray-200"
            >
              <CommonIcon
                v-if="getSelectedOptionIcon(selectedValue)"
                :name="getSelectedOptionIcon(selectedValue)"
                class="shrink-0 fill-gray-100 dark:fill-neutral-400"
                size="xs"
                decorative
              />
              <span
                v-tooltip="
                  getSelectedOptionLabel(selectedValue) || i18n.t('%s (unknown)', selectedValue)
                "
                class="line-clamp-3 break-word"
              >
                {{ getSelectedOptionLabel(selectedValue) || i18n.t('%s (unknown)', selectedValue) }}
              </span>
              <CommonIcon
                :aria-label="i18n.t('Unselect option')"
                class="shrink-0 fill-stone-200 hover:fill-black focus-visible:rounded-xs focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800 dark:fill-neutral-500 dark:hover:fill-white"
                name="x-lg"
                size="xs"
                role="button"
                tabindex="0"
                @click.stop="selectOption(getSelectedOption(selectedValue))"
                @keypress.enter.prevent.stop="selectOption(getSelectedOption(selectedValue))"
                @keypress.space.prevent.stop="selectOption(getSelectedOption(selectedValue))"
              />
            </div>
          </div>
        </div>
        <CommonInputSearch
          v-if="expanded && !context.noFiltering"
          ref="filter-input"
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
              v-tooltip="
                getSelectedOptionLabel(currentValue) || i18n.t('%s (unknown)', currentValue)
              "
              class="line-clamp-3 break-word"
            >
              {{ getSelectedOptionLabel(currentValue) || i18n.t('%s (unknown)', currentValue) }}
            </span>
          </div>
        </div>
        <CommonIcon
          v-if="context.clearable && hasValue && !context.disabled"
          :aria-label="i18n.t('Clear selection')"
          class="shrink-0 fill-stone-200 hover:fill-black focus:outline-transparent focus-visible:rounded-xs focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800 dark:fill-neutral-500 dark:hover:fill-white"
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
    </CommonSelect>
  </div>
</template>
