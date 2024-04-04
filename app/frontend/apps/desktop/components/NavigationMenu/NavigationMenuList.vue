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
  <nav class="flex p-0">
    <TransitionGroup
      tag="ul"
      name="fade-move"
      class="m-0 flex basis-full flex-col gap-1 p-0"
    >
      <li v-for="entry in items" :key="entry.label">
        <CommonLink
          class="flex gap-2 rounded-md px-2 py-3 text-sm text-gray-100 hover:bg-blue-600 hover:text-black hover:no-underline dark:text-neutral-400 dark:hover:bg-blue-900 dark:hover:text-white"
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
