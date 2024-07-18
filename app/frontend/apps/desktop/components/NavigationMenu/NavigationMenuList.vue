<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import {
  NavigationMenuDensity,
  type NavigationMenuEntry,
} from '#desktop/components/NavigationMenu/types.ts'

interface Props {
  items: NavigationMenuEntry[]
  density?: NavigationMenuDensity
}

const props = withDefaults(defineProps<Props>(), {
  density: NavigationMenuDensity.Comfortable,
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
          class="flex gap-2 rounded-md text-sm text-gray-100 hover:bg-blue-600 hover:text-black hover:no-underline focus:outline-none focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800 dark:text-neutral-400 dark:hover:bg-blue-900 dark:hover:text-white"
          :class="[paddingClasses]"
          exact-active-class="!bg-blue-800 w-full !text-white"
          internal
          :link="entry.route"
        >
          <slot v-bind="entry">
            <CommonLabel
              class="grow text-current"
              :prefix-icon="entry.icon"
              :icon-color="entry.iconColor"
            >
              {{ $t(entry.label) }}
            </CommonLabel>
            <CommonLabel
              v-if="typeof entry.count !== 'undefined'"
              class="text-black dark:text-white"
            >
              {{ entry.count }}
            </CommonLabel>
          </slot>
        </CommonLink>
      </li>
    </ul>
  </nav>
</template>
