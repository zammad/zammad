<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, useTemplateRef } from 'vue'

import { i18n } from '#shared/i18n.ts'

import CommonInputSearch from '#desktop/components/CommonInputSearch/CommonInputSearch.vue'

const props = defineProps<{
  title?: string
}>()

const search = defineModel<string>({ default: '' })

const placeholder = computed(() => i18n.t(__('Search within %s…'), props.title))

const clearOnEscape = () => {
  if (!search.value) return

  search.value = ''
}

const inputElement = useTemplateRef('search-input')

defineExpose({ focus: () => inputElement.value?.focus() })
</script>

<template>
  <div class="mb-4 flex shrink-0">
    <CommonInputSearch
      ref="search-input"
      v-model="search"
      :placeholder="placeholder"
      wrapper-class="rounded-lg w-full bg-blue-200 px-2.5 py-2 dark:bg-gray-700 hover:outline-1 hover:outline-blue-600
dark:hover:outline-blue-900 has-[input:focus]:outline-1 has-[input:focus]:outline-blue-800"
      @keydown.esc.stop="clearOnEscape"
    >
      <template #controls>
        <slot name="controls" />
      </template>
    </CommonInputSearch>
  </div>
</template>
