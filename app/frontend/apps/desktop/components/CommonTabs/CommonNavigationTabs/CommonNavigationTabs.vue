<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonNavigationTab from '#desktop/components/CommonTabs/CommonNavigationTabs/CommonNavigationTab.vue'
import TabsOverflowMenu from '#desktop/components/CommonTabs/TabsOverflowMenu.vue'
import TabsScrollList from '#desktop/components/CommonTabs/TabsScrollList.vue'
import type { NavigationTab } from '#desktop/components/CommonTabs/types.ts'

interface Props {
  tabs: NavigationTab[]
  label?: string
  size?: 'medium' | 'large'
  mode?: 'scroll' | 'overflow'
}

const props = withDefaults(defineProps<Props>(), {
  size: 'large',
  mode: 'overflow',
})

const isOverflowMode = computed(() => props.mode === 'overflow')

const appearanceStyling = computed(() => {
  if (isOverflowMode.value) return 'rounded-lg'

  return 'rounded-full'
})

// The active key is usually driven by the current route.
const modelValue = defineModel<NavigationTab['key']>()

const activeKeys = computed(() => (modelValue.value == null ? [] : [modelValue.value]))

const updateModelValue = (tab: NavigationTab) => {
  modelValue.value = tab.key
}
</script>

<template>
  <nav
    :aria-label="label"
    class="relative flex bg-blue-200 p-1 dark:bg-gray-700"
    :class="appearanceStyling"
  >
    <TabsOverflowMenu
      v-if="isOverflowMode"
      :tabs="props.tabs"
      :active-keys="activeKeys"
      :label="props.label"
    >
      <template #default="{ tab, active, tabClass, tabActiveClass }">
        <CommonNavigationTab
          v-tooltip="tab.tooltip"
          v-bind="tab"
          :class="[tabClass, { [tabActiveClass]: active }]"
          :active-keys="activeKeys"
          :size="size"
          :tab-id="tab.key"
          @select="updateModelValue(tab)"
        />
      </template>

      <template #overflow-item="{ tab, close, active, itemClass, itemActiveClass }">
        <CommonNavigationTab
          v-tooltip="tab.tooltip"
          v-bind="tab"
          :class="[itemClass, { [itemActiveClass]: active }]"
          :classes="{
            badge: 'ms-auto',
          }"
          :active-keys="activeKeys"
          :size="size"
          :tab-id="tab.key"
          @select="
            () => {
              updateModelValue(tab)
              close()
            }
          "
        />
      </template>
    </TabsOverflowMenu>

    <TabsScrollList v-else :tabs="tabs" :active-keys="activeKeys" :label="label">
      <template #default="{ tab, tabClass }">
        <CommonNavigationTab
          v-tooltip="tab.tooltip"
          v-bind="tab"
          :class="tabClass"
          :active-keys="activeKeys"
          :size="size"
          :tab-id="tab.key"
          @select="updateModelValue(tab)"
        />
      </template>
    </TabsScrollList>
  </nav>
</template>
