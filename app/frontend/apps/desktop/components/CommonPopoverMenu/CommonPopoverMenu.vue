<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, type SetupContext, toRefs, useSlots } from 'vue'

import type { ObjectLike } from '#shared/types/utils.ts'

import type { CommonPopoverInstance } from '#desktop/components/CommonPopover/types.ts'
import { usePopoverMenu } from '#desktop/components/CommonPopoverMenu/usePopoverMenu.ts'

import CommonPopoverMenuItem from './CommonPopoverMenuItem.vue'

import type { MenuItem, Variant } from './types'

export interface Props {
  popover: CommonPopoverInstance | undefined
  headerLabel?: string
  items?: MenuItem[]
  entity?: ObjectLike
}

const props = defineProps<Props>()

const emit = defineEmits<{
  'click-item': [MenuItem, MouseEvent]
}>()

const { items, entity } = toRefs(props)

const { filteredMenuItems } = usePopoverMenu(items, entity)

/**
 * Workaround to satisfy linter
 * @bug https://github.com/vuejs/language-tools/issues/5082
 * Wait to be closed
 * */
const slots: SetupContext['slots'] = useSlots()

const showHeaderLabel = computed(() => {
  if (!filteredMenuItems.value && !slots.default) return false

  return slots.header || props.headerLabel
})

const onClickItem = (event: MouseEvent, item: MenuItem) => {
  if (item.onClick) {
    event.preventDefault()
    item.onClick(props.entity)
  }

  if (!item.noCloseOnClick) {
    props.popover?.closePopover()
  }

  emit('click-item', item, event)
}

const getHoverFocusStyles = (variant?: Variant) => {
  if (variant === 'secondary')
    return 'hover:bg-blue-500 active:bg-blue-600 dark:hover:bg-blue-950 dark:active:bg-blue-900'

  if (variant === 'danger')
    return 'hover:bg-pink-100 active:bg-red-400 active:**:text-white! dark:active:bg-red-600! dark:hover:bg-red-900'

  return 'hover:bg-blue-600 dark:hover:bg-blue-900 active:bg-blue-800! active:**:text-white!'
}
</script>

<template>
  <section class="flex max-w-64 min-w-58 flex-col gap-0.5">
    <div v-if="showHeaderLabel" role="heading" aria-level="2" class="px-2 py-1.5">
      <slot name="header">
        <CommonLabel
          class="line-clamp-1 text-stone-200! dark:text-neutral-500! cursor-default"
          size="small"
        >
          {{ i18n.t(headerLabel) }}
        </CommonLabel>
      </slot>
    </div>

    <template v-if="filteredMenuItems || $slots.default">
      <slot>
        <ul v-if="filteredMenuItems" role="menu" v-bind="$attrs" class="flex w-full flex-col">
          <template v-for="(item, index) in filteredMenuItems" :key="item.key">
            <li
              v-if="'array' in item"
              class="group flex flex-col overflow-clip pt-2.5 last:rounded-b-[10px] [&:nth-child(n+2)]:border-t [&:nth-child(n+2)]:border-neutral-100 [&:nth-child(n+2)]:dark:border-gray-900"
              role="menuitem"
            >
              <CommonLabel
                size="small"
                class="line-clamp-1 px-2 text-stone-200! dark:text-neutral-500!"
                role="heading"
                aria-level="3"
                >{{ item.groupLabel }}</CommonLabel
              >
              <template v-for="subItem in item.array" :key="subItem.key">
                <slot :name="`item-${subItem.key}`" v-bind="subItem">
                  <component
                    :is="subItem.component || CommonPopoverMenuItem"
                    class="flex grow rounded-lg p-2.5"
                    :class="[
                      getHoverFocusStyles(subItem.variant),
                      {
                        'last:rounded-b-xl': index === filteredMenuItems?.length - 1,
                      },
                    ]"
                    :label="subItem.label"
                    :variant="subItem.variant"
                    :link="subItem.link"
                    :link-external="subItem.linkExternal"
                    :open-in-new-tab="subItem.openInNewTab"
                    :icon="subItem.icon"
                    :icon-class="subItem.iconClass"
                    :label-placeholder="subItem.labelPlaceholder"
                    @click="onClickItem($event, subItem)"
                  />
                  <slot :name="`itemRight-${subItem.key}`" v-bind="subItem" />
                </slot>
              </template>
            </li>
            <li
              v-else
              role="menuitem"
              class="group flex items-center justify-between last:rounded-b-[10px]"
              :class="[
                {
                  'first:rounded-t-[10px]': !showHeaderLabel,
                  'border-t border-neutral-100 dark:border-gray-900': item.separatorTop,
                },
                getHoverFocusStyles(item.variant),
              ]"
            >
              <slot :name="`item-${item.key}`" v-bind="item">
                <component
                  :is="item.component || CommonPopoverMenuItem"
                  class="focus-visible-app-default flex grow p-2.5 focus-visible:-outline-offset-1!"
                  :class="{
                    'rounded-t-lg!': index === 0 && !showHeaderLabel,
                    'rounded-b-lg!': index === filteredMenuItems?.length - 1,
                  }"
                  :label="item.label"
                  :variant="item.variant"
                  :link="item.link"
                  :link-external="item.linkExternal"
                  :open-in-new-tab="item.openInNewTab"
                  :icon="item.icon"
                  :icon-class="item.iconClass"
                  :label-placeholder="item.labelPlaceholder"
                  @click="onClickItem($event, item)"
                />
                <slot :name="`itemRight-${item.key}`" v-bind="item" />
              </slot>
            </li>
            <slot :item="item" name="trailing-item" />
          </template>
        </ul>
      </slot>
    </template>
  </section>
</template>
