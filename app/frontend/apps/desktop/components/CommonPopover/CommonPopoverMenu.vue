<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { ref, computed, useSlots } from 'vue'

import { useSessionStore } from '#shared/stores/session.ts'

import type { CommonPopoverInstance, MenuItem } from './types'
import CommonPopoverMenuItem from './CommonPopoverMenuItem.vue'

export interface Props {
  headerLabel?: string
  items?: MenuItem[]
}

const props = defineProps<Props>()

const popover = ref<CommonPopoverInstance>()

const session = useSessionStore()

const itemsWithPermission = computed(() => {
  if (!props.items || !props.items.length) return null

  return props.items.filter((item) => {
    if (item.permission) {
      return session.hasPermission(item.permission)
    }

    return true
  })
})

const slots = useSlots()

const showHeaderLabel = computed(() => {
  if (!itemsWithPermission.value && !slots.default) return false

  return slots.header || props.headerLabel
})

defineExpose({
  popover,
})
</script>

<template>
  <section class="flex flex-col gap-0.5 min-w-58">
    <div v-if="showHeaderLabel" role="heading" class="p-2 leading-3">
      <slot name="header"
        ><CommonLabel
          size="small"
          class="text-stone-200 dark:text-neutral-500"
          >{{ i18n.t(headerLabel) }}</CommonLabel
        ></slot
      >
    </div>

    <template v-if="itemsWithPermission || $slots.default">
      <slot>
        <ul role="menu" v-bind="$attrs" class="flex w-full flex-col">
          <template v-for="item in itemsWithPermission" :key="item.key">
            <li
              role="menuitem"
              class="group flex items-center justify-between hover:bg-blue-600 dark:hover:bg-blue-900 last:hover:rounded-b-[10px]"
              :class="{
                'first:hover:rounded-t-[10px]': !showHeaderLabel,
                'border-t border-neutral-100 dark:border-gray-900':
                  item.seperatorTop,
              }"
            >
              <CommonPopoverMenuItem
                class="grow flex p-2"
                :label="item.label"
                :link="item.link"
                :icon="item.icon"
                :label-placeholder="item.labelPlaceholder"
                @click="item.onClick?.($event)"
              />
              <slot name="itemRight" v-bind="item" />
            </li>
          </template>
        </ul>
      </slot>
    </template>
  </section>
</template>
