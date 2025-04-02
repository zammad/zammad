<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { BadgeVariant } from '#shared/components/CommonBadge/types.ts'
import type { Sizes } from '#shared/components/CommonLabel/types.ts'

import {
  NavigationMenuDensity,
  type NavigationMenuEntry,
} from '#desktop/components/NavigationMenu/types.ts'

interface Props {
  items: NavigationMenuEntry[]
  density?: NavigationMenuDensity
  countVariant?: BadgeVariant
  countSize?: Sizes
}

const props = withDefaults(defineProps<Props>(), {
  density: NavigationMenuDensity.Comfortable,
  countVariant: 'info',
  countSize: 'xs',
})

const paddingClasses = computed(() =>
  props.density === NavigationMenuDensity.Dense ? 'px-2 py-1' : 'px-2 py-3',
)
</script>

<template>
  <nav class="flex p-0">
    <ul class="m-0 flex basis-full flex-col gap-1 p-0">
      <li v-for="entry in items" :key="entry.label">
        <CommonLink
          class="flex items-center gap-1 rounded-md text-sm text-gray-100 hover:bg-blue-600 hover:text-black hover:no-underline! focus:outline-hidden focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800 dark:text-neutral-400 dark:hover:bg-blue-900 dark:hover:text-white"
          :class="[paddingClasses]"
          exact-active-class="bg-blue-800! w-full text-white!"
          internal
          :link="entry.route"
        >
          <template #default="{ isActive }">
            <slot v-bind="entry">
              <CommonIcon
                v-if="entry.icon"
                size="small"
                aria-hidden="true"
                class="h-4 shrink-0"
                :class="entry.iconColor"
                :name="entry.icon"
              />
              <CommonLabel class="line-clamp-1! grow text-current!">
                {{ $t(entry.label) }}
              </CommonLabel>
              <CommonBadge
                v-if="entry.count !== undefined"
                class="leading-snug font-bold"
                :size="countSize"
                :variant="countVariant"
                :class="{
                  'bg-transparent! text-white!': isActive,
                }"
                rounded
              >
                {{ entry.count }}
              </CommonBadge>
            </slot>
          </template>
        </CommonLink>
      </li>
    </ul>
  </nav>
</template>
