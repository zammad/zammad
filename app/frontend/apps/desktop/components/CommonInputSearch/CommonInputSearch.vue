<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useVModel } from '@vueuse/core'
import { useTemplateRef, computed } from 'vue'

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

defineOptions({
  inheritAttrs: false,
})

const props = withDefaults(defineProps<CommonInputSearchProps>(), {
  placeholder: __('Search…'),
})

const emit = defineEmits<{
  'update:modelValue': [filter: string]
  keydown: [event: KeyboardEvent]
  'focus-input': []
  'blur-input': []
}>()

const filter = useVModel(props, 'modelValue', emit)

const filterInput = useTemplateRef('filter-input')

const focus = () => filterInput.value?.focus()

const blur = () => filterInput.value?.blur()

defineExpose({ focus, blur })

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

const onKeydown = (event: KeyboardEvent) => emit('keydown', event)
</script>

<template>
  <div
    class="inline-flex grow items-center justify-start gap-1 text-sm"
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
          ref="filter-input"
          v-model="filter"
          v-bind="$attrs"
          :placeholder="i18n.t(placeholder)"
          :aria-label="$t('Search…')"
          class="w-full min-w-16 text-black outline-hidden dark:text-white"
          :class="{
            'bg-blue-200 dark:bg-gray-700': !alternativeBackground,
            'bg-neutral-50 dark:bg-gray-500': alternativeBackground,
          }"
          type="text"
          role="searchbox"
          autocomplete="off"
          @keydown.right="maybeAcceptSuggestion"
          @keydown.end="maybeAcceptSuggestion"
          @keydown.tab="maybeAcceptSuggestion"
          @keydown="onKeydown"
          @focus="emit('focus-input')"
          @blur="emit('blur-input')"
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
        class="fill-stone-200 hover:fill-black focus-visible:rounded-xs focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800 dark:fill-neutral-500 dark:hover:fill-white"
        :class="{
          invisible: !filter?.length,
        }"
        :aria-label="$t('Clear Search')"
        :aria-hidden="!filter?.length ? 'true' : undefined"
        name="backspace2"
        size="xs"
        role="button"
        :tabindex="!filter?.length ? '-1' : '0'"
        @click.stop="clearFilter()"
        @keypress.space.prevent.stop="clearFilter()"
      />
    </div>
  </div>
</template>
