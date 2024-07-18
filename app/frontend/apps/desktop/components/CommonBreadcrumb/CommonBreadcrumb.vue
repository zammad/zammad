<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { useLocaleStore } from '#shared/stores/locale.ts'

import type { BreadcrumbItem } from './types.ts'

const props = defineProps<{
  items: BreadcrumbItem[]
  emphasizeLastItem?: boolean
  size?: 'small' | 'large'
}>()

const locale = useLocaleStore()
// TODO: Missing handling when there is not enough space for the breadcrumb

const lastItemClasses = computed(() => {
  return props.emphasizeLastItem ? ['last:dark:text-white last:text-black'] : []
})

const sizeClasses = computed(() => {
  if (props.size === 'small') return ['text-xs']

  return ['text-base'] // default -> 'large'
})
</script>

<template>
  <nav
    :class="sizeClasses"
    :aria-label="$t('Breadcrumb navigation')"
    class="max-w-full"
  >
    <ol class="flex">
      <li
        v-for="(item, idx) in items"
        :key="item.label as string"
        class="flex items-center"
        :class="lastItemClasses"
      >
        <CommonIcon
          v-if="item.icon"
          :name="item.icon"
          size="xs"
          class="shrink-0 ltr:mr-1 rtl:ml-1"
        />

        <CommonLink
          v-if="item.route"
          class="focus:outline-none focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800"
          :link="item.route"
          internal
        >
          <CommonLabel size="large" class="line-clamp-1 hover:underline">{{
            item.noOptionLabelTranslation
              ? $t(item.label as string)
              : item.label
          }}</CommonLabel>
        </CommonLink>

        <h1 v-else class="line-clamp-1" aria-current="page">
          {{
            item.noOptionLabelTranslation
              ? $t(item.label as string)
              : item.label
          }}
        </h1>

        <CommonIcon
          v-if="idx !== items.length - 1"
          :name="
            locale.localeData?.dir === 'rtl' ? 'chevron-left' : 'chevron-right'
          "
          size="xs"
          class="mx-1 inline-flex shrink-0"
        />

        <!-- Add a slot at the end of the last item. -->
        <slot v-if="idx === items.length - 1" name="trailing" />
      </li>
    </ol>
  </nav>
</template>
