<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { ConcreteComponent, Ref } from 'vue'
import { computed, nextTick, onMounted, ref, toRef, watch } from 'vue'
import { useRouter } from 'vue-router'
import { cloneDeep } from 'lodash-es'
import { refDebounced } from '@vueuse/core'
import { useLazyQuery } from '@vue/apollo-composable'
import gql from 'graphql-tag'
import type { NameNode, OperationDefinitionNode, SelectionNode } from 'graphql'
import CommonInputSearch from '@shared/components/CommonInputSearch/CommonInputSearch.vue'
import CommonDialog from '@mobile/components/CommonDialog/CommonDialog.vue'
import { QueryHandler } from '@shared/server/apollo/handler'
import { closeDialog } from '@shared/composables/useDialog'
import FieldAutoCompleteOptionIcon from './FieldAutoCompleteOptionIcon.vue'
import useSelectOptions from '../../composables/useSelectOptions'
import useValue from '../../composables/useValue'
import type { FormFieldContext } from '../../types/field'
import { AutoCompleteOption } from './types'
import type { AutoCompleteProps } from './types'

const props = defineProps<{
  context: FormFieldContext<
    AutoCompleteProps & {
      gqlQuery: string
    }
  >
  name: string
  options: AutoCompleteOption[]
  optionIconComponent: ConcreteComponent
}>()

const { isCurrentValue } = useValue(toRef(props, 'context'))

const emit = defineEmits<{
  (e: 'updateOptions', options: AutoCompleteOption[]): void
}>()

const { sortedOptions, selectOption, advanceDialogFocus } = useSelectOptions(
  toRef(props, 'options'),
  toRef(props, 'context'),
)

let areLocalOptionsReplaced = false

const replacementLocalOptions: Ref<AutoCompleteOption[]> = ref(
  cloneDeep(props.options),
)

const filter = ref('')

const clearFilter = () => {
  filter.value = ''
}

const filterInput = ref(null)

const focusFirstTarget = () => {
  const filterInputElement = filterInput.value as null | HTMLElement
  if (filterInputElement) filterInputElement.focus()
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
  useLazyQuery(AutocompleteSearchDocument, () => ({
    query: debouncedFilter.value,
    limit: props.context.limit,
  })),
)

watch(
  () => debouncedFilter.value,
  (newValue) => {
    if (!newValue.length) return
    autocompleteQueryHandler.load()
  },
)

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

const autocompleteOptions = computed(
  () => autocompleteQueryResultOptions.value || [],
)

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

  close()
}

const OptionIconComponent =
  props.optionIconComponent ?? FieldAutoCompleteOptionIcon

const router = useRouter()

const executeAction = () => {
  if (!props.context.action) return
  router.push(props.context.action)
}
</script>

<template>
  <CommonDialog
    :name="name"
    :label="$t(context.label)"
    :listeners="{ done: { onKeydown: advanceDialogFocus } }"
    @close="close"
  >
    <template #before-label>
      <div
        v-if="context.action"
        class="absolute top-0 left-0 bottom-0 flex items-center pl-4"
      >
        <div
          class="grow cursor-pointer text-white"
          tabindex="0"
          role="button"
          @click="close"
          @keypress.space="close"
          @keydown="advanceDialogFocus"
        >
          {{ i18n.t('Cancel') }}
        </div>
      </div>
    </template>
    <template #after-label>
      <div class="absolute top-0 right-0 bottom-0 flex items-center pr-4">
        <CommonIcon
          v-if="context.action"
          :name="context.actionIcon ? context.actionIcon : 'external'"
          :fixed-size="{ width: 24, height: 24 }"
          class="cursor-pointer text-white"
          tabindex="0"
          role="button"
          @click="executeAction"
          @keypress.space="executeAction"
          @keydown="advanceDialogFocus"
        />
        <div
          v-else
          class="grow cursor-pointer text-blue"
          tabindex="0"
          role="button"
          @click="close()"
          @keypress.space="close()"
          @keydown="advanceDialogFocus"
        >
          {{ i18n.t('Done') }}
        </div>
      </div>
    </template>
    <div class="w-full p-4">
      <CommonInputSearch ref="filterInput" v-model="filter" />
    </div>
    <div
      class="flex grow flex-col items-start self-stretch overflow-y-auto"
      role="listbox"
    >
      <div
        v-for="(option, index) in filter
          ? sortedAutocompleteOptions
          : sortedOptions"
        :key="option.value"
        :class="{
          'pointer-events-none': option.disabled,
        }"
        :tabindex="option.disabled ? '-1' : '0'"
        :aria-selected="isCurrentValue(option.value)"
        class="relative flex h-[58px] cursor-pointer items-center self-stretch px-6 py-5 text-base leading-[19px] text-white focus:bg-blue-highlight focus:outline-none"
        role="option"
        @click="select(option as AutoCompleteOption)"
        @keypress.space="select(option as AutoCompleteOption)"
        @keydown="advanceDialogFocus($event, option)"
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
          :fixed-size="{ width: 24, height: 24 }"
          :name="isCurrentValue(option.value) ? 'checked-yes' : 'checked-no'"
          class="mr-3 text-white/50"
        />
        <OptionIconComponent :option="option" />
        <div
          v-if="(option as AutoCompleteOption).heading"
          class="flex grow flex-col"
        >
          <span
            :class="{
              'opacity-30': option.disabled,
            }"
            class="grow text-sm text-gray-100"
          >
            {{ (option as AutoCompleteOption).heading }}
          </span>
          <span
            :class="{
              'opacity-30': option.disabled,
            }"
            class="grow text-lg font-semibold leading-[22px]"
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
          class="grow text-white/80"
        >
          {{ option.label || option.value }}
        </span>
        <CommonIcon
          v-if="!context.multiple && isCurrentValue(option.value)"
          :class="{
            'opacity-30': option.disabled,
          }"
          :fixed-size="{ width: 16, height: 16 }"
          name="check"
        />
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
        {{ i18n.t('No results found') }}
      </div>
      <div
        v-else-if="!debouncedFilter && !options.length"
        class="relative flex h-[58px] items-center justify-center self-stretch py-5 px-4 text-base leading-[19px] text-white/50"
        role="alert"
      >
        {{ i18n.t('Start typing to search…') }}
      </div>
    </div>
  </CommonDialog>
</template>
