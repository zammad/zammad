<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

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
          class="focus:outline-hidden focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800"
          :link="item.route"
          internal
        >
          <CommonLabel size="large" class="line-clamp-1 hover:underline">{{
            item.noOptionLabelTranslation
              ? item.label
              : $t(item.label as string)
          }}</CommonLabel>
        </CommonLink>

        <component
          :is="items.at(-1) === item ? 'h1' : 'span'"
          v-else
          class="line-clamp-1"
          :class="{ 'text-black dark:text-white': item.isActive }"
          aria-current="page"
        >
          {{
            item.noOptionLabelTranslation
              ? item.label
              : $t(item.label as string)
          }}
        </component>

        <CommonBadge
          v-if="item.count !== undefined"
          class="leading-snug font-bold ltr:ml-1.5 rtl:mr-1.5"
          size="xs"
          rounded
        >
          {{ item.count }}
        </CommonBadge>

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
