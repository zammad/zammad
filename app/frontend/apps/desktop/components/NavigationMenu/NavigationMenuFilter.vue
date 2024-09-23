<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useActiveElement, useMagicKeys, onClickOutside } from '@vueuse/core'
import { nextTick, ref, watchEffect, useTemplateRef } from 'vue'

import CommonIcon from '#shared/components/CommonIcon/CommonIcon.vue'
import { useTransitionConfig } from '#shared/composables/useTransitionConfig.ts'
import { i18n } from '#shared/i18n.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

const filterFieldOpen = ref(false)
const containerElement = useTemplateRef('container')
const searchText = defineModel<string>({ required: true, default: '' })
const searchTextElement = useTemplateRef('search-text')

onClickOutside(containerElement, () => {
  if (searchText.value !== '') return

  filterFieldOpen.value = false
})

const activeElement = useActiveElement()
const { escape } = useMagicKeys()

const openFilterField = () => {
  filterFieldOpen.value = true

  nextTick(() => searchTextElement.value?.focus())
}

const closeFilterField = () => {
  filterFieldOpen.value = false
  searchText.value = ''
}

watchEffect(() => {
  if (!escape.value) return
  if (activeElement.value !== searchTextElement.value) return

  closeFilterField()
})

const { durations } = useTransitionConfig()
</script>

<template>
  <div
    ref="container"
    class="mb-2 flex h-10 shrink-0 items-center gap-2 rounded-lg transition-colors"
    :class="{
      'bg-blue-200 px-2 has-[input:focus]:outline has-[input:hover]:outline has-[input:focus]:outline-1 has-[input:hover]:outline-1 has-[input:focus]:outline-offset-1 has-[input:hover]:outline-offset-1 has-[input:focus]:outline-blue-800 has-[input:hover]:has-[input:focus]:outline-blue-800 has-[input:hover]:outline-blue-600 dark:bg-gray-700 dark:has-[input:hover]:has-[input:focus]:outline-blue-800 dark:has-[input:hover]:outline-blue-900':
        filterFieldOpen,
    }"
  >
    <CommonIcon
      v-if="filterFieldOpen"
      class="fill-stone-200 dark:fill-neutral-500"
      size="small"
      name="filter"
      decorative
    />
    <CommonButton
      v-else
      class="ltr:ml-auto rtl:mr-auto"
      prefix-icon="filter"
      @click="openFilterField"
    >
      {{ $t('apply filter') }}
    </CommonButton>

    <input
      ref="search-text"
      v-model.trim="searchText"
      :placeholder="$t('Apply filter…')"
      :aria-label="$t('Navigation filter')"
      class="w-0 bg-transparent text-sm text-black transition-[width] duration-200 focus:outline-none dark:text-white"
      :class="{ 'w-full': filterFieldOpen }"
      type="text"
      role="searchbox"
    />
    <Transition name="fade-move" :duration="durations.normal">
      <CommonButton
        v-if="filterFieldOpen"
        icon="x-lg"
        variant="neutral"
        class="hover:text-black hover:outline-none hover:outline-transparent hover:dark:text-white"
        :aria-label="i18n.t('Clear filter')"
        @click="closeFilterField"
      />
    </Transition>
  </div>
</template>
