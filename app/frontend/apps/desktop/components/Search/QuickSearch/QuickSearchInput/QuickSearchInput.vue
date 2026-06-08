<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useTemplateRef, watch } from 'vue'
import { useRouter } from 'vue-router'

import {
  KeyboardKey,
  type OrderKeyHandlerConfig,
} from '#shared/composables/useKeyboardEventBus/types.ts'
import { useKeyboardEventBus } from '#shared/composables/useKeyboardEventBus/useKeyboardEventBus.ts'
import { useOnEmitter } from '#shared/composables/useOnEmitter.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonInputSearch from '#desktop/components/CommonInputSearch/CommonInputSearch.vue'

const searchValue = defineModel<string>()

const isSearchActive = defineModel<boolean>('search-active', {
  default: false,
})

const inputSearchInstance = useTemplateRef('input-search')

const router = useRouter()

const resetInput = () => {
  searchValue.value = ''
  isSearchActive.value = false
  // Blur input to make sure it does not get refocuses automatically and focus event is not emitted
  inputSearchInstance.value?.blur()
}

const goToSearchView = () => {
  router.push({ name: 'Search', params: { searchTerm: searchValue.value } })
  resetInput()
}

const keyHandlerConfig: OrderKeyHandlerConfig = {
  handler: resetInput,
  key: 'quick-search-input',
}

const { subscribeEvent, unsubscribeEvent } = useKeyboardEventBus(
  KeyboardKey.Escape,
  keyHandlerConfig,
)

watch(isSearchActive, (isActive) =>
  isActive ? subscribeEvent(keyHandlerConfig) : unsubscribeEvent(keyHandlerConfig),
)

useOnEmitter('focus-quick-search-field', () => inputSearchInstance.value?.focus())
useOnEmitter('reset-quick-search-field', () => resetInput())
</script>

<template>
  <div class="flex items-center gap-3">
    <CommonInputSearch
      ref="input-search"
      v-model="searchValue"
      wrapper-class="rounded-lg bg-blue-200 px-2.5 py-2 outline-blue-800 focus-within:outline dark:bg-gray-700"
      @focus-input="isSearchActive = true"
      @keydown.enter="goToSearchView"
    />
    <CommonButton
      v-if="isSearchActive"
      :aria-label="$t('Reset search')"
      icon="x-lg"
      variant="neutral"
      @click="resetInput"
    />
  </div>
</template>
