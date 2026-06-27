<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts" generic="T extends Tab | NavigationTab">
import { computed, ref, toRef, useTemplateRef } from 'vue'

import { EnumTextDirection } from '#shared/graphql/types.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonPopover from '#desktop/components/CommonPopover/CommonPopover.vue'
import { usePopover } from '#desktop/components/CommonPopover/usePopover.ts'
import TabOverflowItem from '#desktop/components/CommonTabs/TabOverflowItem.vue'
import type { Tab, NavigationTab } from '#desktop/components/CommonTabs/types.ts'

interface Props {
  tabs: T[]
  activeKeys: T['key'][]
  label?: string
  multiple?: boolean
  containerRole?: string
  listItemRole?: string
}

const props = defineProps<Props>()

defineOptions({
  inheritAttrs: false,
})

const containerElement = useTemplateRef<HTMLElement>('container')

const locale = useLocaleStore()
const localeData = toRef(locale, 'localeData')
const isLtrLocale = computed(() => localeData.value?.dir !== EnumTextDirection.Rtl)

// Reserve 27.5px on the trailing edge for the overflow button width + padding 4px
const rootMargin = computed(() => (isLtrLocale.value ? '0px -32px 0px 0px' : '0px 0px 0px -32px'))

// Each TabOverflowItem reports its own visibility
const visibleTabs = ref(new Map<string, boolean>())

const handleVisible = (key: string, isVisible: boolean) => {
  visibleTabs.value.set(key, isVisible)
}

const overflowTabsData = computed<T[]>(() =>
  props.tabs.filter((tab) => visibleTabs.value.get(tab.key) === false),
)

const { popover, popoverTarget, isOpen: isPopoverOpen, toggle: togglePopover, close } = usePopover()
</script>

<template>
  <ul
    ref="container"
    :aria-label="label"
    :role="containerRole"
    :aria-multiselectable="multiple || undefined"
    class="relative isolate scroll-bar-hidden flex snap-x flex-row items-center overflow-x-hidden [&>[data-tab]+[data-tab]]:ms-1"
  >
    <TabOverflowItem
      v-for="tab in tabs"
      :key="tab.key"
      data-tab
      :role="listItemRole"
      :container="containerElement"
      :root-margin="rootMargin"
      @visible="handleVisible(tab.key, $event)"
    >
      <slot
        :tab="tab"
        :active="activeKeys.includes(tab.key)"
        tab-class="rounded-sm! focus-visible-app-default px-3 py-1 -outline-offset-1!"
        tab-active-class="bg-blue-800! text-white!"
      />
    </TabOverflowItem>

    <li class="sticky inset-e-0 h-full">
      <CommonButton
        ref="popoverTarget"
        v-tooltip="$t('Show more tabs')"
        variant="none"
        icon="three-dots-vertical"
        class="z-10 aspect-square h-full! rounded-sm! bg-neutral-50/80 p-1.5! text-black -outline-offset-1! backdrop-blur-xs dark:bg-gray-500/80 dark:text-white"
        :class="[{ 'bg-blue-800! text-white!': isPopoverOpen }]"
        :disabled="!overflowTabsData.length"
        :aria-expanded="isPopoverOpen"
        @click="togglePopover(true)"
      />
    </li>
  </ul>

  <template v-if="overflowTabsData.length">
    <CommonPopover
      ref="popover"
      class="min-w-58"
      :owner="popoverTarget"
      orientation="bottom"
      placement="end"
      hide-arrow
    >
      <ul class="flex w-full flex-col" role="menu">
        <li
          v-for="tab in overflowTabsData"
          :key="tab.key"
          role="menuitem"
          class="group flex h-full items-center text-gray-100 first:*:rounded-t-[11px]! last:*:rounded-b-[11px]!"
        >
          <slot
            name="overflow-item"
            :tab="tab"
            :active="activeKeys.includes(tab.key)"
            :close="close"
            item-class="w-full p-2.5 focus-visible-app-default hover:bg-blue-600 hover:text-black focus-visible:-outline-offset-1! active:bg-blue-800! active:text-white! dark:text-neutral-400 dark:hover:bg-blue-900 dark:hover:text-white"
            item-active-class="bg-blue-800! text-white!"
          />
        </li>
      </ul>
    </CommonPopover>
  </template>
</template>
