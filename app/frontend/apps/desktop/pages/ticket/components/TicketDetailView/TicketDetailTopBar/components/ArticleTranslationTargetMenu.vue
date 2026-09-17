<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, nextTick, ref, useTemplateRef, watch } from 'vue'

import type { SelectOption } from '#shared/components/CommonSelect/types.ts'
import { useTraverseOptions } from '#shared/composables/useTraverseOptions.ts'
import { useArticleTranslationStore } from '#shared/entities/ticket-article/stores/articleTranslation.ts'
import getUuid from '#shared/utils/getUuid.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonInputSearch from '#desktop/components/CommonInputSearch/CommonInputSearch.vue'
import CommonPopover from '#desktop/components/CommonPopover/CommonPopover.vue'
import { usePopover } from '#desktop/components/CommonPopover/usePopover.ts'
import CommonSelectItem from '#desktop/components/CommonSelect/CommonSelectItem.vue'

const store = useArticleTranslationStore()

// A11y - Ids are required to link the popover and the language list to their labels.
const targetId = getUuid()
const languageHeadingId = getUuid()

const { popover, popoverTarget, isOpen, toggle, close } = usePopover()

const currentLocale = computed(() => store.targetLocale)
const currentName = computed(() => store.targetLocaleName)

const localeCode = computed(() => store.targetLocale?.toUpperCase() ?? '')

const options = computed<SelectOption[]>(
  () => store.targetLocales?.map(({ locale, name }) => ({ value: locale, label: name })) ?? [],
)

const filter = ref('')

const filteredOptions = computed(() => {
  const term = filter.value.trim().toLowerCase()
  if (!term) return options.value

  return options.value.filter(
    ({ label, value }) =>
      label?.toLowerCase().includes(term) || value.toString().toLowerCase().includes(term),
  )
})

const searchInput = useTemplateRef('search-input')
const listElement = useTemplateRef('list')

useTraverseOptions(listElement)

const focusFirstOption = () =>
  listElement.value?.querySelector<HTMLElement>('[role="option"][tabindex="0"]')?.focus()

watch(isOpen, (open) => {
  if (!open) {
    filter.value = ''
    return
  }

  nextTick(() => searchInput.value?.focus())
})

const select = (option: SelectOption) => {
  store.setTargetLocale(option.value.toString())
  close()
}
</script>

<template>
  <div class="flex" data-test-id="article-translation-target-menu">
    <CommonButton
      :id="targetId"
      ref="popoverTarget"
      v-tooltip="$t('Translation to %s', currentName)"
      variant="tertiary-light"
      size="small"
      class="h-7! px-2! -outline-offset-1!"
      :class="{ 'outline-1! outline-blue-800!': isOpen }"
      prefix-icon="translate"
      :aria-expanded="isOpen"
      @click="toggle(true)"
    >
      <span
        class="inline-flex items-center gap-1 text-xs whitespace-nowrap text-black dark:text-white"
        aria-hidden="true"
      >
        {{ localeCode }}
        <CommonIcon
          class="text-stone-200 dark:text-neutral-500"
          decorative
          size="xs"
          name="chevron-down"
        />
      </span>
    </CommonButton>
  </div>

  <CommonPopover
    ref="popover"
    :owner="popoverTarget"
    orientation="autoVertical"
    placement="arrowEnd"
  >
    <div class="flex w-72 flex-col overflow-clip rounded-b-xl">
      <!-- The switch for translating the whole ticket comes with the automatic translation. -->

      <div class="flex flex-col gap-1.5 px-2.5 pt-2.5 pb-2">
        <CommonLabel
          :id="languageHeadingId"
          class="cursor-default text-stone-200! dark:text-neutral-500!"
          size="small"
          role="heading"
          aria-level="2"
        >
          {{ $t('Target language') }}
        </CommonLabel>

        <CommonInputSearch
          ref="search-input"
          v-model="filter"
          wrapper-class="rounded-lg bg-blue-200 px-2.5 py-1.5 dark:bg-gray-700"
          @keydown.down.prevent="focusFirstOption()"
        />
      </div>

      <div
        ref="list"
        class="max-h-64 overflow-y-auto"
        role="listbox"
        tabindex="-1"
        :aria-labelledby="languageHeadingId"
      >
        <CommonSelectItem
          v-for="option in filteredOptions"
          :key="option.value.toString()"
          :option="option"
          :selected="option.value === currentLocale"
          no-label-translate
          class="last:rounded-b-xl!"
          @select="select"
        />

        <CommonSelectItem
          v-if="!filteredOptions.length"
          :option="{ value: '', label: __('No results found') }"
          no-selection-indicator
          no-interaction
        />
      </div>
    </div>
  </CommonPopover>
</template>
