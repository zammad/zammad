<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useLazyQuery } from '@vue/apollo-composable'
import {
  refDebounced,
  useElementBounding,
  useWindowSize,
  watchOnce,
} from '@vueuse/core'
import gql from 'graphql-tag'
import { cloneDeep, escapeRegExp, isEqual } from 'lodash-es'
import {
  computed,
  markRaw,
  nextTick,
  ref,
  toRef,
  watch,
  type ConcreteComponent,
} from 'vue'

import type { SelectOption } from '#shared/components/CommonSelect/types'
import useValue from '#shared/components/Form/composables/useValue.ts'
import type {
  AutoCompleteOption,
  AutocompleteSelectValue,
} from '#shared/components/Form/fields/FieldAutocomplete/types.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import useSelectOptions from '#shared/composables/useSelectOptions.ts'
import { useTrapTab } from '#shared/composables/useTrapTab.ts'
import { useFormBlock } from '#shared/form/useFormBlock.ts'
import { i18n } from '#shared/i18n.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

import CommonInputSearch from '#desktop/components/CommonInputSearch/CommonInputSearch.vue'
import CommonSelect from '#desktop/components/CommonSelect/CommonSelect.vue'
import type { CommonSelectInstance } from '#desktop/components/CommonSelect/types'

import FieldAutoCompleteOptionIcon from './FieldAutoCompleteOptionIcon.vue'

import type {
  AutoCompleteProps,
  SelectOptionFunction,
  ClearFilterInputFunction,
  AutoCompleteOptionValueDictionary,
} from './types.ts'
import type { FormKitNode } from '@formkit/core'
import type { NameNode, OperationDefinitionNode, SelectionNode } from 'graphql'

interface Props {
  context: FormFieldContext<AutoCompleteProps>
}

const emit = defineEmits<{
  searchInteractionUpdate: [
    filter: string,
    optionValues: AutoCompleteOptionValueDictionary,
    selectOption: SelectOptionFunction,
    clearFilter: ClearFilterInputFunction,
  ]
  keydownFilterInput: [
    event: KeyboardEvent,
    filter: string,
    optionValues: AutoCompleteOptionValueDictionary,
    selectOption: SelectOptionFunction,
    clearFilter: ClearFilterInputFunction,
  ]
}>()

const props = defineProps<Props>()
const contextReactive = toRef(props, 'context')

const { hasValue, valueContainer, currentValue, isCurrentValue, clearValue } =
  useValue<AutocompleteSelectValue>(contextReactive)

// TODO: I think clearValue needs to wrapper for the full clear of the field (to remove some of the remembered stuff).

const localOptions = ref(props.context.options || [])

const {
  sortedOptions,
  appendedOptions,
  optionValueLookup,
  getSelectedOption,
  getSelectedOptionLabel,
} = useSelectOptions<AutoCompleteOption[]>(localOptions, contextReactive)

watch(
  () => props.context.options,
  (options) => {
    localOptions.value = options || []
  },
)

// Remember current optionValueLookup in node context.
contextReactive.value.optionValueLookup = optionValueLookup

// Initial options prefill for non-multiple fields (multiple fields needs to be handled in
// the form updater or via options prop).
let rememberedInitialOptionFromBuilder: AutoCompleteOption | undefined
const initialOptionBuilderHandler = (rootNode: FormKitNode) => {
  if (
    hasValue.value &&
    props.context.initialOptionBuilder &&
    !getSelectedOptionLabel(currentValue.value)
  ) {
    const initialOption = props.context.initialOptionBuilder(
      rootNode?.context?.initialEntityObject as ObjectLike,
      currentValue.value,
      props.context,
    )

    if (initialOption) {
      localOptions.value.push(initialOption)

      if (rememberedInitialOptionFromBuilder) {
        const rememberedOptionValue = rememberedInitialOptionFromBuilder.value

        localOptions.value = localOptions.value.filter(
          (option) => option.value !== rememberedOptionValue,
        )
      }

      rememberedInitialOptionFromBuilder = initialOption
    }
  }
}

if (!props.context.multiple && props.context.initialOptionBuilder) {
  const rootNode = props.context.node.at('$root')

  if (rootNode) {
    initialOptionBuilderHandler(rootNode)

    rootNode?.on('reset', ({ origin }) => {
      initialOptionBuilderHandler(origin)
    })
  }
}

const input = ref<HTMLDivElement>()
const outputElement = ref<HTMLOutputElement>()
const filter = ref('')
const filterInput = ref<HTMLInputElement>()
const select = ref<CommonSelectInstance>()

const { activateTabTrap, deactivateTabTrap } = useTrapTab(input, true)

const clearFilter = () => {
  filter.value = ''
}

const trimmedFilter = computed(() => filter.value.trim())

const debouncedFilter = refDebounced(
  trimmedFilter,
  props.context.debounceInterval ?? 500,
)

const AutocompleteSearchDocument = gql`
  ${props.context.gqlQuery}
`

const additionalQueryParams = () => {
  if (typeof props.context.additionalQueryParams === 'function') {
    return props.context.additionalQueryParams()
  }

  return props.context.additionalQueryParams || {}
}

const defaultFilter = computed(() => {
  if (hasValue.value) return ''
  return props.context.defaultFilter
})

const autocompleteQueryHandler = new QueryHandler(
  useLazyQuery(
    AutocompleteSearchDocument,
    () => ({
      input: {
        query: debouncedFilter.value || defaultFilter.value || '',
        limit: props.context.limit,
        ...(additionalQueryParams() || {}),
      },
    }),
    () => ({
      enabled: !!(debouncedFilter.value || defaultFilter.value),
      cachePolicy: 'no-cache', // Do not use cache, because we want always up-to-date results.
    }),
  ),
)

if (defaultFilter.value) {
  autocompleteQueryHandler.load()
} else {
  watchOnce(
    () => debouncedFilter.value,
    (newValue) => {
      if (!newValue.length) return
      autocompleteQueryHandler.load()
    },
  )
}

const autocompleteQueryResultKey = (
  (AutocompleteSearchDocument.definitions[0] as OperationDefinitionNode)
    .selectionSet.selections[0] as SelectionNode & { name: NameNode }
).name.value

const autocompleteQueryResultOptions = computed<AutoCompleteOption[]>(
  (oldValue) => {
    const resultOptions =
      autocompleteQueryHandler.result().value?.[autocompleteQueryResultKey] ||
      []

    if (oldValue && isEqual(oldValue, resultOptions)) return oldValue

    return resultOptions
  },
)

const autocompleteOptions = computed(
  () => cloneDeep(autocompleteQueryResultOptions.value) || [],
)

const {
  sortedOptions: sortedAutocompleteOptions,
  selectOption: selectAutocompleteOption,
  getSelectedOption: getSelectedAutocompleteOption,
  getSelectedOptionIcon: getSelectedAutocompleteOptionIcon,
  optionValueLookup: autocompleteOptionValueLookup,
} = useSelectOptions<AutoCompleteOption[]>(
  autocompleteOptions,
  toRef(props, 'context'),
)

const preprocessedAutocompleteOptions = computed(() => {
  if (!props.context.autocompleteOptionsPreprocessor)
    return sortedAutocompleteOptions.value

  return props.context.autocompleteOptionsPreprocessor(
    sortedAutocompleteOptions.value,
  )
})

const selectOption = (option: SelectOption, focus = false) => {
  selectAutocompleteOption(option as AutoCompleteOption)

  if (!props.context.multiple) {
    localOptions.value = [option as AutoCompleteOption]
    select.value?.closeDropdown()
    return
  }

  if (!sortedOptions.value.some((elem) => elem.value === option.value)) {
    appendedOptions.value.push(option as AutoCompleteOption)
  }

  appendedOptions.value = appendedOptions.value.filter((elem) =>
    isCurrentValue(elem.value),
  )

  if (focus !== true) return

  filterInput.value?.focus()
}

const selectNewOption = (option: SelectOption, focus = false) => {
  if (isCurrentValue(option.value)) return
  selectOption(option, focus)
}

const availableOptions = computed<AutoCompleteOption[]>((oldValue) => {
  const currentOptions =
    filter.value || defaultFilter.value
      ? preprocessedAutocompleteOptions.value
      : sortedOptions.value

  if (oldValue && isEqual(oldValue, currentOptions)) return oldValue

  return currentOptions
})

const emitResultUpdated = () => {
  nextTick(() => {
    emit(
      'searchInteractionUpdate',
      debouncedFilter.value,
      { ...autocompleteOptionValueLookup.value, ...optionValueLookup.value },
      selectNewOption,
      clearFilter,
    )
  })
}

watch(debouncedFilter, (newValue) => {
  if (newValue !== '' || defaultFilter.value) return

  emitResultUpdated()
})

watch(autocompleteQueryHandler.loading(), (newValue, oldValue) => {
  // We need not to trigger when query was started.
  if (newValue && !oldValue) return

  emitResultUpdated()
})

const onKeydownFilterInput = (event: KeyboardEvent) => {
  nextTick(() => {
    emit(
      'keydownFilterInput',
      event,
      filter.value,
      { ...autocompleteOptionValueLookup.value, ...optionValueLookup.value },
      selectNewOption,
      clearFilter,
    )
  })
}

const deaccent = (s: string) =>
  s.normalize('NFD').replace(/[\u0300-\u036f]/g, '')

const availableOptionsWithMatches = computed(() => {
  // Trim and de-accent search keywords and compile them as a case-insensitive regex.
  //   Make sure to escape special regex characters!
  const filterRegex = new RegExp(
    escapeRegExp(deaccent(filter.value.trim())),
    'i',
  )

  return availableOptions.value.map(
    (option) =>
      ({
        ...option,

        // Match options via their de-accented labels.
        match: filterRegex.exec(deaccent(option.label || String(option.value))),
      }) as AutoCompleteOption,
  )
})

const childOptions = ref<AutoCompleteOption[]>([])

const showChildOptions = (option: AutoCompleteOption) => {
  if (!option.children) return
  childOptions.value = option.children
}

const clearChildOptions = () => {
  if (!childOptions.value.length) return
  childOptions.value = []
}

const displayOptions = computed(() => {
  if (childOptions.value.length) return childOptions.value
  return availableOptionsWithMatches.value
})

const suggestedOptionLabel = computed(() => {
  if (!filter.value || !availableOptionsWithMatches.value.length)
    return undefined

  const exactMatches = availableOptionsWithMatches.value.filter(
    (option) =>
      (option.label || option.value.toString())
        .toLowerCase()
        .indexOf(filter.value.toLowerCase()) === 0 &&
      (option.label || option.value.toString()).length > filter.value.length,
  )

  if (!exactMatches.length) return undefined

  return exactMatches[0].label || exactMatches[0].value.toString()
})

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
  clearChildOptions()
  clearFilter()
  deactivateTabTrap()
}

const onFocusFilterInput = () => {
  filterInput.value?.focus()
}

const OptionIconComponent =
  props.context.optionIconComponent ??
  (FieldAutoCompleteOptionIcon as ConcreteComponent)

useFormBlock(contextReactive, openSelectDropdown)
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
    data-test-id="field-autocomplete"
  >
    <CommonSelect
      ref="select"
      #default="{ state: expanded, close: closeDropdown }"
      :model-value="currentValue"
      :options="displayOptions"
      :multiple="context.multiple"
      :owner="context.id"
      :filter="filter"
      :option-icon-component="markRaw(OptionIconComponent)"
      :empty-initial-label-text="contextReactive.emptyInitialLabelText"
      :actions="context.actions"
      :is-child-page="childOptions.length > 0"
      no-options-label-translation
      no-close
      passive
      initially-empty
      @select="selectOption"
      @push="showChildOptions"
      @pop="clearChildOptions"
      @close="onCloseDropdown"
      @focus-filter-input="onFocusFilterInput"
    >
      <output
        :id="context.id"
        ref="outputElement"
        role="combobox"
        aria-controls="common-select"
        aria-owns="common-select"
        aria-haspopup="menu"
        :aria-expanded="expanded"
        :name="context.node.name"
        class="formkit-disabled:pointer-events-none flex grow items-center gap-2.5 px-2.5 py-2 text-black focus:outline-none dark:text-white"
        :aria-labelledby="`label-${context.id}`"
        :aria-disabled="context.disabled"
        :aria-describedby="context.describedBy"
        aria-autocomplete="none"
        :data-multiple="context.multiple"
        tabindex="0"
        v-bind="context.attrs"
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
            :key="selectedValue.toString()"
            class="flex items-center gap-1.5"
            role="listitem"
          >
            <div
              class="inline-flex items-center gap-1 rounded px-1.5 py-0.5 text-xs text-black dark:text-white"
              :class="{
                'bg-white dark:bg-gray-200': !context.alternativeBackground,
                'bg-neutral-100 dark:bg-gray-200':
                  context.alternativeBackground,
              }"
            >
              <CommonIcon
                v-if="getSelectedAutocompleteOptionIcon(selectedValue)"
                :name="getSelectedAutocompleteOptionIcon(selectedValue)"
                class="shrink-0 fill-gray-100 dark:fill-neutral-400"
                size="xs"
                decorative
              />
              <span
                class="line-clamp-3 whitespace-pre-wrap break-words"
                :title="
                  getSelectedOptionLabel(selectedValue) ||
                  i18n.t('%s (unknown)', selectedValue.toString())
                "
              >
                {{
                  getSelectedOptionLabel(selectedValue) ||
                  i18n.t('%s (unknown)', selectedValue.toString())
                }}
              </span>
              <CommonIcon
                :aria-label="i18n.t('Unselect Option')"
                class="shrink-0 fill-stone-200 hover:fill-black focus:outline-none focus-visible:rounded-sm focus-visible:outline focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800 dark:fill-neutral-500 dark:hover:fill-white"
                name="x-lg"
                size="xs"
                role="button"
                tabindex="0"
                @click.stop="
                  selectOption(
                    getSelectedAutocompleteOption(selectedValue) ||
                      getSelectedOption(selectedValue),
                  )
                "
                @keypress.enter.prevent.stop="
                  selectOption(
                    getSelectedAutocompleteOption(selectedValue) ||
                      getSelectedOption(selectedValue),
                  )
                "
                @keypress.space.prevent.stop="
                  selectOption(
                    getSelectedAutocompleteOption(selectedValue) ||
                      getSelectedOption(selectedValue),
                  )
                "
              />
            </div>
          </div>
        </div>
        <CommonInputSearch
          v-if="expanded || !hasValue"
          ref="filterInput"
          v-model="filter"
          :class="{ 'pointer-events-none': !expanded }"
          :suggestion="suggestedOptionLabel"
          :alternative-background="context.alternativeBackground"
          @keypress.space.stop
          @keydown="onKeydownFilterInput"
        />
        <div v-if="!expanded" class="flex grow flex-wrap gap-1" role="list">
          <div
            v-if="hasValue && !context.multiple"
            class="flex items-center gap-1.5 text-sm"
            role="listitem"
          >
            <CommonIcon
              v-if="getSelectedAutocompleteOptionIcon(currentValue)"
              :name="getSelectedAutocompleteOptionIcon(currentValue)"
              class="shrink-0 fill-gray-100 dark:fill-neutral-400"
              size="tiny"
              decorative
            />
            <span
              class="line-clamp-3 whitespace-pre-wrap break-words"
              :title="
                getSelectedOptionLabel(currentValue) ||
                i18n.t('%s (unknown)', currentValue.toString())
              "
            >
              {{
                getSelectedOptionLabel(currentValue) ||
                i18n.t('%s (unknown)', currentValue.toString())
              }}
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
    </CommonSelect>
  </div>
</template>
