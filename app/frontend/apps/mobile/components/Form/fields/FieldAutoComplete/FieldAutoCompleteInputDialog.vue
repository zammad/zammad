<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useLazyQuery } from '@vue/apollo-composable'
import { refDebounced, watchOnce } from '@vueuse/core'
import gql from 'graphql-tag'
import { cloneDeep } from 'lodash-es'
import { computed, nextTick, onMounted, ref, toRef } from 'vue'
import { useRouter } from 'vue-router'

import useValue from '#shared/components/Form/composables/useValue.ts'
import type {
  AutoCompleteOption,
  AutoCompleteProps,
  AutocompleteSelectValue,
} from '#shared/components/Form/fields/FieldAutocomplete/types.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import useSelectOptions from '#shared/composables/useSelectOptions.ts'
import { useTraverseOptions } from '#shared/composables/useTraverseOptions.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'

import CommonButton from '#mobile/components/CommonButton/CommonButton.vue'
import CommonDialog from '#mobile/components/CommonDialog/CommonDialog.vue'
import { closeDialog } from '#mobile/composables/useDialog.ts'

import FieldAutoCompleteOptionIcon from './FieldAutoCompleteOptionIcon.vue'

import type { FormKitNode } from '@formkit/core'
import type { NameNode, OperationDefinitionNode, SelectionNode } from 'graphql'
import type { ConcreteComponent, Ref } from 'vue'

const props = defineProps<{
  context: FormFieldContext<AutoCompleteProps>
  name: string
  options: AutoCompleteOption[]
  optionIconComponent?: ConcreteComponent | null
  noCloseOnSelect?: boolean
}>()

const contextReactive = toRef(props, 'context')

const { isCurrentValue } = useValue<AutocompleteSelectValue>(contextReactive)

const emit = defineEmits<{
  'update-options': [AutoCompleteOption[]]
  action: []
}>()

const { sortedOptions, selectOption, appendedOptions } = useSelectOptions<
  AutoCompleteOption[]
>(toRef(props, 'options'), contextReactive)

let areLocalOptionsReplaced = false

const replacementLocalOptions: Ref<AutoCompleteOption[]> = ref(
  cloneDeep(props.options),
)

const filter = ref('')

const filterInput = ref(null)

const focusFirstTarget = () => {
  const filterInputFormKit = filterInput.value as null | { node: FormKitNode }
  if (!filterInputFormKit) return

  const filterInputElement = document.getElementById(
    filterInputFormKit.node.context?.id as string,
  )
  if (!filterInputElement) return

  filterInputElement.focus()
}

const clearFilter = () => {
  filter.value = ''
}

onMounted(() => {
  if (areLocalOptionsReplaced) {
    replacementLocalOptions.value = [...props.options]
  }

  nextTick(() => focusFirstTarget())
})

const close = () => {
  if (props.context.multiple) {
    emit('update-options', [...replacementLocalOptions.value])
    replacementLocalOptions.value = []
    areLocalOptionsReplaced = true
  }

  closeDialog(props.name)
  clearFilter()
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

const autocompleteQueryHandler = new QueryHandler(
  useLazyQuery(
    AutocompleteSearchDocument,
    () => ({
      input: {
        query: debouncedFilter.value || props.context.defaultFilter || '',
        limit: props.context.limit,
        ...(additionalQueryParams() || {}),
      },
    }),
    () => ({
      enabled: !!(debouncedFilter.value || props.context.defaultFilter),
      cachePolicy: 'no-cache', // Do not use cache, because we want always up-to-date results.
    }),
  ),
)

if (props.context.defaultFilter) {
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

const autocompleteQueryResultOptions = computed(
  () =>
    autocompleteQueryHandler.result().value?.[
      autocompleteQueryResultKey
    ] as unknown as AutoCompleteOption[],
)

const autocompleteOptions = computed(() => {
  const result = cloneDeep(autocompleteQueryResultOptions.value) || []

  const filterInputFormKit = filterInput.value as null | { node: FormKitNode }

  if (
    props.context.allowUnknownValues &&
    filterInputFormKit &&
    filterInputFormKit.node.context?.state.complete &&
    !result.some((option) => option.value === trimmedFilter.value)
  ) {
    result.unshift({
      value: trimmedFilter.value,
      label: trimmedFilter.value,
    })
  }

  return result
})

const { sortedOptions: sortedAutocompleteOptions } = useSelectOptions(
  autocompleteOptions,
  toRef(props, 'context'),
)

const select = (option: AutoCompleteOption) => {
  selectOption(option)

  if (props.context.multiple) {
    // If the current value contains the selected option, make sure it's added to the replacement list
    //   if it's not already there.
    if (
      isCurrentValue(option.value) &&
      !replacementLocalOptions.value.some(
        (replacementLocalOption) =>
          replacementLocalOption.value === option.value,
      )
    ) {
      replacementLocalOptions.value.push(option)
    }

    // Remove any extra options from the replacement list.
    replacementLocalOptions.value = replacementLocalOptions.value.filter(
      (replacementLocalOption) => isCurrentValue(replacementLocalOption.value),
    )

    if (!sortedOptions.value.some((elem) => elem.value === option.value)) {
      appendedOptions.value.push(option)
    }

    appendedOptions.value = appendedOptions.value.filter((elem) =>
      isCurrentValue(elem.value),
    )

    // Sort the replacement list according to the original order.
    replacementLocalOptions.value.sort(
      (a, b) =>
        sortedOptions.value.findIndex((option) => option.value === a.value) -
        sortedOptions.value.findIndex((option) => option.value === b.value),
    )

    return
  }

  emit('update-options', [option])

  if (!props.noCloseOnSelect) {
    close()
  }
}

const OptionIconComponent =
  props.optionIconComponent ?? FieldAutoCompleteOptionIcon

const router = useRouter()

const executeAction = () => {
  emit('action')
  if (!props.context.action) return
  router.push(props.context.action)
}

const autocompleteList = ref<HTMLElement>()

useTraverseOptions(autocompleteList)
</script>

<template>
  <CommonDialog
    :name="name"
    :label="context.label"
    class="field-autocomplete-dialog"
    @close="close"
  >
    <template v-if="context.action || context.onActionClick" #before-label>
      <CommonButton
        class="grow"
        transparent-background
        @click="close"
        @keypress.space="close"
      >
        {{ $t('Cancel') }}
      </CommonButton>
    </template>
    <template #after-label>
      <button
        v-if="context.action || context.onActionClick"
        tabindex="0"
        :aria-label="context.actionLabel"
        @click="executeAction"
        @keypress.space="executeAction"
      >
        <CommonIcon
          :name="context.actionIcon ? context.actionIcon : 'external-link'"
          class="cursor-pointer text-white"
          size="base"
        />
      </button>
      <CommonButton
        v-else
        class="grow"
        variant="primary"
        transparent-background
        @click="close()"
        @keypress.space="close()"
      >
        {{ $t('Done') }}
      </CommonButton>
    </template>
    <div class="w-full p-4">
      <FormKit
        ref="filterInput"
        v-model="filter"
        :delay="context.node.props.delay"
        :placeholder="context.filterInputPlaceholder"
        :validation="context.filterInputValidation"
        type="search"
        validation-visibility="live"
        role="searchbox"
      />
    </div>
    <div
      v-if="filter ? autocompleteOptions.length : options.length"
      ref="autocompleteList"
      :aria-label="$t('Select…')"
      class="flex grow flex-col items-start self-stretch overflow-y-auto"
      role="listbox"
      :aria-multiselectable="context.multiple"
    >
      <div
        v-for="(option, index) in filter || context.defaultFilter
          ? sortedAutocompleteOptions
          : sortedOptions"
        :key="String(option.value)"
        :class="{
          'pointer-events-none': option.disabled,
        }"
        aria-setsize="-1"
        :aria-posinset="options.findIndex((o) => o.value === option.value) + 1"
        tabindex="0"
        :aria-selected="isCurrentValue(option.value)"
        class="focus:bg-blue-highlight relative flex h-[58px] cursor-pointer items-center self-stretch px-6 py-5 text-base leading-[19px] text-white focus:outline-none"
        role="option"
        @click="select(option as AutoCompleteOption)"
        @keyup.space="select(option as AutoCompleteOption)"
      >
        <div
          v-if="index !== 0"
          :class="{
            'ltr:left-4 rtl:right-4': !context.multiple && !option.icon,
            'ltr:left-[60px] rtl:right-[60px]':
              context.multiple && !option.icon,
            'ltr:left-[72px] rtl:right-[72px]':
              !context.multiple && option.icon,
            'ltr:left-[108px] rtl:right-[108px]':
              context.multiple && option.icon,
          }"
          class="absolute top-0 h-0 border-t border-white/10 ltr:right-4 rtl:left-4"
        />
        <CommonIcon
          v-if="context.multiple"
          :class="{
            '!text-white': isCurrentValue(option.value),
            'opacity-30': option.disabled,
          }"
          :name="
            isCurrentValue(option.value) ? 'check-box-yes' : 'check-box-no'
          "
          class="text-white/50 ltr:mr-3 rtl:ml-3"
          size="base"
          decorative
        />
        <OptionIconComponent :option="option" />
        <div
          v-if="(option as AutoCompleteOption).heading"
          class="flex grow flex-col overflow-hidden"
        >
          <span
            :class="{
              'opacity-30': option.disabled,
            }"
            class="flex-1 truncate text-sm text-gray-100"
          >
            <span>{{ (option as AutoCompleteOption).heading }}</span>
          </span>
          <span
            :class="{
              'opacity-30': option.disabled,
            }"
            class="grow truncate text-lg font-semibold leading-[22px]"
          >
            {{ option.label || option.value }}
          </span>
        </div>
        <span
          v-else
          :class="{
            'font-semibold !text-white': isCurrentValue(option.value),
            'opacity-30': option.disabled,
          }"
          class="grow truncate text-white/80"
        >
          {{ option.label || option.value }}
        </span>
        <CommonIcon
          v-if="!context.multiple && isCurrentValue(option.value)"
          :class="{
            'opacity-30': option.disabled,
          }"
          size="tiny"
          name="check"
          decorative
        />
      </div>
    </div>
    <div
      v-if="
        debouncedFilter &&
        autocompleteQueryResultOptions &&
        !autocompleteOptions.length
      "
      class="relative flex h-[58px] items-center justify-center self-stretch px-4 py-5 text-base leading-[19px] text-white/50"
      role="alert"
    >
      {{ $t(context.dialogNotFoundMessage || __('No results found')) }}
    </div>
    <div
      v-else-if="!debouncedFilter && !options.length"
      class="relative flex h-[58px] items-center justify-center self-stretch px-4 py-5 text-base leading-[19px] text-white/50"
      role="alert"
    >
      {{ $t(context.dialogEmptyMessage || __('Start typing to search…')) }}
    </div>
  </CommonDialog>
</template>

<style>
.field-autocomplete-dialog {
  .formkit-wrapper {
    @apply px-0;
  }
}
</style>
