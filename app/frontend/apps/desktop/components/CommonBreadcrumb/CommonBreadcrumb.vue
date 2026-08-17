<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { i18n } from '#shared/i18n.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'

import type { BreadcrumbItem } from './types.ts'

const props = withDefaults(
  defineProps<{
    items: BreadcrumbItem[]
    emphasizeLastItem?: boolean
    size?: 'small' | 'large'
    label?: string
  }>(),
  {
    size: 'large',
    label: __('Breadcrumb navigation'),
  },
)

const locale = useLocaleStore()
// TODO: Missing handling when there is not enough space for the breadcrumb

const lastItemClasses = computed(() => {
  return props.emphasizeLastItem ? ['last:dark:text-white last:text-black'] : []
})

const sizeClasses = computed(() => {
  if (props.size === 'small') return ['text-xs']

  return ['text-base'] // default -> 'large'
})

const getItemLabel = (item: BreadcrumbItem) =>
  item.noOptionLabelTranslation ? (item.label as string) : i18n.t(item.label as string)

const displayItems = computed(() =>
  props.items.map((item) => Object.assign({}, item, { displayLabel: getItemLabel(item) })),
)
</script>

<template>
  <nav :class="sizeClasses" :aria-label="$t(label)" class="max-w-full">
    <ol class="flex">
      <li
        v-for="(item, idx) in displayItems"
        :key="item.label as string"
        class="flex items-center"
        :class="[lastItemClasses, { 'print:hidden': idx === 0 }]"
      >
        <CommonIcon
          v-if="!item.route && item.icon"
          :name="item.icon"
          size="xs"
          class="shrink-0 ltr:mr-1 rtl:ml-1"
          :class="item.iconClass"
        />

        <CommonLink
          v-if="item.route && item.iconOnly"
          v-tooltip="item.displayLabel"
          class="inline-flex items-center focus-visible-app-default"
          :link="item.route"
          internal
        >
          <CommonIcon
            v-if="item.icon"
            :name="item.icon"
            size="xs"
            class="shrink-0"
            :class="item.iconClass"
          />
        </CommonLink>

        <CommonLink
          v-else-if="item.route"
          v-tooltip.supportive="item.displayLabel"
          class="inline-flex items-center gap-1 focus-visible-app-default"
          :link="item.route"
          internal
        >
          <CommonIcon
            v-if="item.icon"
            :name="item.icon"
            size="xs"
            class="shrink-0"
            :class="item.iconClass"
          />

          <CommonLabel class="line-clamp-1! hover:text-black hover:dark:text-white" :size="size">
            {{ item.displayLabel }}
          </CommonLabel>
        </CommonLink>

        <component
          :is="displayItems.at(-1) === item ? 'h1' : 'span'"
          v-else
          v-tooltip.supportive="item.displayLabel"
          class="line-clamp-1"
          :class="{
            'text-black dark:text-white': item.isActive,
            'break-all': displayItems.at(-1) === item,
          }"
          aria-current="page"
        >
          {{ item.displayLabel }}
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
          v-if="idx !== displayItems.length - 1"
          :name="locale.localeData?.dir === 'rtl' ? 'chevron-left' : 'chevron-right'"
          size="xs"
          class="mx-1 inline-flex shrink-0 text-stone-200 dark:text-neutral-500"
        />

        <!-- Add a slot at the end of the last item. -->
        <slot v-if="idx === displayItems.length - 1" name="trailing" />
      </li>
    </ol>
  </nav>
</template>
