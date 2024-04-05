<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { NavigationMenuEntry } from '#desktop/components/NavigationMenu/types.ts'
import CommonLabel from '#shared/components/CommonLabel/CommonLabel.vue'

interface Props {
  items: NavigationMenuEntry[]
}

defineProps<Props>()
</script>

<template>
  <nav class="p-0 flex">
    <TransitionGroup
      tag="ul"
      name="fade-move"
      class="m-0 p-0 basis-full flex flex-col gap-1"
    >
      <li v-for="entry in items" :key="entry.label">
        <CommonLink
          class="px-2 py-3 hover:no-underline flex gap-2 text-gray-100 dark:text-neutral-400 hover:text-black dark:hover:text-white hover:bg-blue-600 dark:hover:bg-blue-900 text-sm rounded-md"
          exact-active-class="!bg-blue-800 w-full !text-white"
          internal
          :link="entry.route"
        >
          <slot v-bind="entry">
            <CommonLabel class="text-current">
              {{ $t(entry.label) }}
            </CommonLabel>
          </slot>
        </CommonLink>
      </li>
    </TransitionGroup>
  </nav>
</template>
