<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useVModel } from '@vueuse/core'
import { computed, shallowRef } from 'vue'

export interface CommonInputSearchProps {
  modelValue?: string
  wrapperClass?: string
  placeholder?: string
  suggestion?: string
  alternativeBackground?: boolean
}

export interface CommonInputSearchExpose {
  focus(): void
}

const props = withDefaults(defineProps<CommonInputSearchProps>(), {
  placeholder: __('Search…'),
})

const emit = defineEmits<{
  'update:modelValue': [filter: string]
  keydown: [event: KeyboardEvent]
}>()

const filter = useVModel(props, 'modelValue', emit)

const filterInput = shallowRef<HTMLInputElement>()

const focus = () => {
  filterInput.value?.focus()
}

defineExpose({ focus })

const clearFilter = () => {
  filter.value = ''
  focus()
}

const suggestionVisiblePart = computed(() =>
  props.suggestion?.slice(filter.value?.length),
)

const maybeAcceptSuggestion = (event: Event) => {
  if (
    !props.suggestion ||
    !filter.value ||
    !filterInput.value ||
    !filterInput.value.selectionStart ||
    filter.value.length >= props.suggestion.length ||
    filterInput.value.selectionStart < filter.value.length
  )
    return

  event.preventDefault()
  filter.value = props.suggestion
}

const onKeydown = (event: KeyboardEvent) => {
  emit('keydown', event)
}
</script>

<script lang="ts">
export default {
  inheritAttrs: false,
}
</script>

<template>
  <div
    class="inline-flex grow items-center justify-start gap-1"
    :class="wrapperClass"
  >
    <CommonIcon
      class="shrink-0 fill-stone-200 dark:fill-neutral-500"
      size="tiny"
      name="search"
      decorative
    />
    <div class="relative inline-flex grow overflow-clip">
      <div class="grow">
        <input
          ref="filterInput"
          v-model="filter"
          v-bind="$attrs"
          :placeholder="i18n.t(placeholder)"
          :aria-label="$t('Search…')"
          class="w-full min-w-16 text-black outline-none dark:text-white"
          :class="{
            'bg-blue-200 dark:bg-gray-700': !alternativeBackground,
            'bg-white dark:bg-gray-500': alternativeBackground,
          }"
          type="text"
          role="searchbox"
          @keydown.right="maybeAcceptSuggestion"
          @keydown.end="maybeAcceptSuggestion"
          @keydown.tab="maybeAcceptSuggestion"
          @keydown="onKeydown"
        />
      </div>
      <div
        v-if="suggestionVisiblePart?.length"
        class="pointer-events-none absolute top-0 flex whitespace-pre"
        data-test-id="suggestion"
      >
        <span class="invisible">{{ filter }}</span>
        <span class="text-stone-200 dark:text-neutral-500">{{
          suggestionVisiblePart
        }}</span>
      </div>
    </div>
    <div class="flex shrink-0 items-center gap-1">
      <slot name="controls" />
      <CommonIcon
        class="fill-stone-200 hover:fill-black focus-visible:rounded-sm focus-visible:outline focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800 dark:fill-neutral-500 dark:hover:fill-white"
        :class="{
          invisible: !filter?.length,
        }"
        :aria-label="i18n.t('Clear Search')"
        :aria-hidden="!filter?.length ? 'true' : undefined"
        name="backspace2"
        size="tiny"
        role="button"
        :tabindex="!filter?.length ? '-1' : '0'"
        @click.stop="clearFilter()"
        @keypress.space.prevent.stop="clearFilter()"
      />
    </div>
  </div>
</template>
