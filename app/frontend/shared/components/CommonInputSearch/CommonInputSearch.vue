<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useVModel } from '@vueuse/core'
import { shallowRef } from 'vue'

export interface CommonInputSearchProps {
  modelValue?: string
  noBorder?: boolean
  wrapperClass?: string
}

export interface CommonInputSearchEmits {
  (e: 'update:modelValue', filter: string): void
}

export interface CommonInputSearchExpose {
  focus(): void
}

const props = defineProps<CommonInputSearchProps>()
const emit = defineEmits<CommonInputSearchEmits>()

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
</script>

<script lang="ts">
export default {
  inheritAttrs: false,
}
</script>

<template>
  <div
    class="relative flex w-full items-center self-stretch"
    :class="wrapperClass"
  >
    <CommonIcon
      :fixed-size="{ width: 24, height: 24 }"
      class="absolute shrink-0 text-gray ltr:left-2 rtl:right-2"
      name="search"
      decorative
    />
    <input
      ref="filterInput"
      v-model="filter"
      v-bind="$attrs"
      :placeholder="i18n.t('Search…')"
      class="h-12 w-full grow rounded-xl bg-gray-500 px-9 placeholder:text-gray focus:shadow-none focus:outline-none focus:ring-0"
      :class="{
        'focus:border-white focus:ring-0': !noBorder,
        'focus:border-transparent': noBorder,
      }"
      type="text"
      role="searchbox"
    />
    <CommonIcon
      v-if="filter && filter.length"
      :aria-label="i18n.t('Clear Search')"
      :fixed-size="{ width: 24, height: 24 }"
      class="absolute shrink-0 text-gray ltr:right-2 rtl:left-2"
      name="close-small"
      @click.stop="clearFilter"
    />
  </div>
</template>
