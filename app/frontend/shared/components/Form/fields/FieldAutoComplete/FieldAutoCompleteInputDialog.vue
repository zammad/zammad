<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { ConcreteComponent, Ref } from 'vue'
import { computed, nextTick, onMounted, ref, toRef } from 'vue'
import { useRouter } from 'vue-router'
import { cloneDeep } from 'lodash-es'
import { refDebounced, watchOnce } from '@vueuse/core'
import { useLazyQuery } from '@vue/apollo-composable'
import gql from 'graphql-tag'
import type { NameNode, OperationDefinitionNode, SelectionNode } from 'graphql'
import CommonDialog from '@mobile/components/CommonDialog/CommonDialog.vue'
import { QueryHandler } from '@shared/server/apollo/handler'
import { useTraverseOptions } from '@shared/composables/useTraverseOptions'
import { closeDialog } from '@shared/composables/useDialog'
import type { FormKitNode } from '@formkit/core'
import FieldAutoCompleteOptionIcon from './FieldAutoCompleteOptionIcon.vue'
import useSelectOptions from '../../composables/useSelectOptions'
import useValue from '../../composables/useValue'
import type { FormFieldContext } from '../../types/field'
import { AutoCompleteOption } from './types'
import type { AutoCompleteProps } from './types'

const props = defineProps<{
  context: FormFieldContext<AutoCompleteProps>
  name: string
  options: AutoCompleteOption[]
  optionIconComponent: ConcreteComponent
  noCloseOnSelect?: boolean
}>()

const contextReactive = toRef(props, 'context')

const { isCurrentValue } = useValue(contextReactive)

const emit = defineEmits<{
  (e: 'updateOptions', options: AutoCompleteOption[]): void
  (e: 'action'): void
}>()

const { sortedOptions, selectOption } = useSelectOptions(
  toRef(props, 'options'),
  contextReactive,
)

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
    emit('updateOptions', [...replacementLocalOptions.value])
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

// TODO: Check the cache policy for this query, because already triggered searches are re-used from the cache and if
//   the source was changed in the meantime, the result will not be updated. It's unclear if there is a subscription in
//   place to update the result on any changes.
const autocompleteQueryHandler = new QueryHandler(
  useLazyQuery(
    AutocompleteSearchDocument,
    () => ({
      input: {
        query: debouncedFilter.value || props.context.defaultFilter || '',
        limit: props.context.limit,
        ...(props.context.additionalQueryParams || {}),
      },
    }),
    () => ({
      enabled: !!(debouncedFilter.value || props.context.defaultFilter),
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

    // Sort the replacement list according to the original order.
    replacementLocalOptions.value.sort(
      (a, b) =>
        sortedOptions.value.findIndex((option) => option.value === a.value) -
        sortedOptions.value.findIndex((option) => option.value === b.value),
    )

    return
  }

  emit('updateOptions', [option])

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
      <div
        class="grow cursor-pointer text-white"
        tabindex="0"
        role="button"
        @click="close"
        @keypress.space="close"
      >
        {{ i18n.t('Cancel') }}
      </div>
    </template>
    <template #after-label>
      <CommonIcon
        v-if="context.action || context.onActionClick"
        :name="context.actionIcon ? context.actionIcon : 'mobile-external-link'"
        :label="context.actionLabel"
        class="cursor-pointer text-white"
        size="base"
        tabindex="0"
        role="button"
        @click="executeAction"
        @keypress.space="executeAction"
      />
      <div
        v-else
        class="grow cursor-pointer text-blue"
        tabindex="0"
        role="button"
        @click="close()"
        @keypress.space="close()"
      >
        {{ i18n.t('Done') }}
      </div>
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
        :tabindex="option.disabled ? '-1' : '0'"
        :aria-selected="isCurrentValue(option.value)"
        class="relative flex h-[58px] cursor-pointer items-center self-stretch px-6 py-5 text-base leading-[19px] text-white focus:bg-blue-highlight focus:outline-none"
        role="option"
        @click="select(option as AutoCompleteOption)"
        @keypress.space="select(option as AutoCompleteOption)"
      >
        <div
          v-if="index !== 0"
          :class="{
            'left-4': !context.multiple && !option.icon,
            'left-[60px]': context.multiple && !option.icon,
            'left-[72px]': !context.multiple && option.icon,
            'left-[108px]': context.multiple && option.icon,
          }"
          class="absolute right-4 top-0 h-0 border-t border-white/10"
        />
        <CommonIcon
          v-if="context.multiple"
          :class="{
            '!text-white': isCurrentValue(option.value),
            'opacity-30': option.disabled,
          }"
          :name="
            isCurrentValue(option.value)
              ? 'mobile-check-box-yes'
              : 'mobile-check-box-no'
          "
          class="mr-3 text-white/50"
          size="base"
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
            class="flex-1 overflow-hidden text-ellipsis whitespace-nowrap text-sm text-gray-100"
          >
            <span>{{ (option as AutoCompleteOption).heading }}</span>
          </span>
          <!-- since it has fixed height, we add ellipsis on the first line -->
          <!-- TODO: should it be fixed? or we should allow multiline with maximum lines (3?) -->
          <span
            :class="{
              'opacity-30': option.disabled,
            }"
            class="grow overflow-hidden text-ellipsis whitespace-nowrap text-lg font-semibold leading-[22px]"
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
          class="grow overflow-hidden text-ellipsis whitespace-nowrap text-white/80"
        >
          {{ option.label || option.value }}
        </span>
        <CommonIcon
          v-if="!context.multiple && isCurrentValue(option.value)"
          :class="{
            'opacity-30': option.disabled,
          }"
          size="tiny"
          name="mobile-check"
        />
      </div>
    </div>
    <div
      v-if="
        debouncedFilter &&
        autocompleteQueryResultOptions &&
        !autocompleteOptions.length
      "
      class="relative flex h-[58px] items-center justify-center self-stretch py-5 px-4 text-base leading-[19px] text-white/50"
      role="alert"
    >
      {{ i18n.t(context.dialogNotFoundMessage || __('No results found')) }}
    </div>
    <div
      v-else-if="!debouncedFilter && !options.length"
      class="relative flex h-[58px] items-center justify-center self-stretch py-5 px-4 text-base leading-[19px] text-white/50"
      role="alert"
    >
      {{ i18n.t(context.dialogEmptyMessage || __('Start typing to search…')) }}
    </div>
  </CommonDialog>
</template>

<style lang="scss">
.field-autocomplete-dialog {
  .formkit-wrapper {
    @apply px-0;
  }
}
</style>
