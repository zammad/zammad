<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, useSlots } from 'vue'

import { useSessionStore } from '#shared/stores/session.ts'

import type { CommonPopoverInstance, MenuItem } from './types'
import CommonPopoverMenuItem from './CommonPopoverMenuItem.vue'

export interface Props {
  popover: CommonPopoverInstance | undefined
  headerLabel?: string
  items?: MenuItem[]
}

const props = defineProps<Props>()

const session = useSessionStore()

const availableItems = computed(() => {
  if (!props.items || !props.items.length) return null

  return props.items.filter((item) => {
    if (item.permission) {
      return session.hasPermission(item.permission)
    }

    if (item.show) {
      return item.show()
    }

    return true
  })
})

const slots = useSlots()

const showHeaderLabel = computed(() => {
  if (!availableItems.value && !slots.default) return false

  return slots.header || props.headerLabel
})

const onClickItem = (event: MouseEvent, item: MenuItem) => {
  if (item.onClick) {
    item.onClick(event)
  }

  if (!item.noCloseOnClick) {
    props.popover?.closePopover()
  }
}
</script>

<template>
  <section class="min-w-58 flex flex-col gap-0.5">
    <div v-if="showHeaderLabel" role="heading" class="p-2 leading-3">
      <slot name="header"
        ><CommonLabel
          size="small"
          class="text-stone-200 dark:text-neutral-500"
          >{{ i18n.t(headerLabel) }}</CommonLabel
        ></slot
      >
    </div>

    <template v-if="availableItems || $slots.default">
      <slot>
        <ul role="menu" v-bind="$attrs" class="flex w-full flex-col">
          <template v-for="item in availableItems" :key="item.key">
            <li
              role="menuitem"
              class="group flex items-center justify-between last:rounded-b-[10px] focus-within:bg-blue-800 focus-within:text-white hover:bg-blue-600 hover:focus-within:bg-blue-800 dark:hover:bg-blue-900 dark:hover:focus-within:bg-blue-800"
              :class="{
                'first:rounded-t-[10px]': !showHeaderLabel,
                'border-t border-neutral-100 dark:border-gray-900':
                  item.separatorTop,
              }"
            >
              <slot :name="`item-${item.key}`" v-bind="item">
                <component
                  :is="item.component || CommonPopoverMenuItem"
                  class="flex grow p-2.5"
                  :label="item.label"
                  :link="item.link"
                  :icon="item.icon"
                  :label-placeholder="item.labelPlaceholder"
                  @click="onClickItem($event, item)"
                />
                <slot :name="`itemRight-${item.key}`" v-bind="item" />
              </slot>
            </li>
          </template>
        </ul>
      </slot>
    </template>
  </section>
</template>
