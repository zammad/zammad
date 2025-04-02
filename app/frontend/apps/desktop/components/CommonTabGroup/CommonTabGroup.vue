<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useResizeObserver } from '@vueuse/core'
import { computed, ref, useTemplateRef, watch } from 'vue'

import CommonTab from '#desktop/components/CommonTabGroup/CommonTab.vue'
import type { Tab } from '#desktop/components/CommonTabGroup/types.ts'

interface Props {
  multiple?: boolean
  label?: string
  tabs: Tab[]
  modelValue?: Tab['key'] | Tab['key'][]
  size?: 'medium' | 'large'
}

const props = withDefaults(defineProps<Props>(), {
  size: 'large',
})

const emit = defineEmits<{
  'update:modelValue': [Tab['key'] | Tab['key'][]]
}>()

const containerElement = useTemplateRef('container')
const markerElement = useTemplateRef('marker')
const tabInstances = useTemplateRef('tabs')

const isTabMode = computed(() => !props.multiple)
const labelSize = computed(() => (props.size === 'large' ? 'medium' : 'small'))

const defaultTabIndex = computed(() =>
  props.tabs.findIndex((tab) => tab.default),
)

const selectedIndex = ref<number | null>(null)

const activeTabs = computed(() =>
  Array.isArray(props.modelValue) ? props.modelValue : [props.modelValue],
)

const isActiveTab = (tab: Tab) => activeTabs.value.includes(tab.key)

const calcMarkerSize = () => {
  const tabElement = tabInstances.value?.at(
    selectedIndex.value ?? defaultTabIndex.value,
  )
  if (!tabElement || !markerElement.value) return

  Object.assign(markerElement.value.style, {
    top: `${tabElement.$el.offsetTop}px`,
    left: `${tabElement.$el.offsetLeft}px`,
    width: `${tabElement.$el.offsetWidth}px`,
    height: `${tabElement.$el.offsetHeight}px`,
  })
}

watch(
  () => props.modelValue,
  (activeTabKey) => {
    if (props.multiple) return
    selectedIndex.value = props.tabs.findIndex(
      (tab) => activeTabKey === tab.key,
    )
    calcMarkerSize()
  },
)

useResizeObserver(containerElement, calcMarkerSize)

const updateModelValue = (tab: Tab, index: number) => {
  if (tab.disabled) return

  if (!props.multiple) {
    selectedIndex.value = index
    calcMarkerSize()
    return emit('update:modelValue', tab.key)
  }

  const updatedTabs = activeTabs.value.includes(tab.key)
    ? activeTabs.value.filter((activeTab) => activeTab !== tab.key)
    : [...activeTabs.value, tab.key]

  emit('update:modelValue', updatedTabs as Tab['key'][])
}

if (!props.multiple) {
  const initialTabIndex = props.modelValue
    ? props.tabs.findIndex((tab) => activeTabs.value.includes(tab.key))
    : defaultTabIndex.value

  if (initialTabIndex === -1) updateModelValue(props.tabs[0], 0)
  else updateModelValue(props.tabs[initialTabIndex], initialTabIndex)
}
</script>

<template>
  <div
    ref="container"
    :role="isTabMode ? 'tablist' : 'listbox'"
    class="relative flex w-fit items-center gap-1 rounded-full bg-blue-200 p-1 dark:bg-gray-700"
  >
    <CommonLabel
      v-if="label"
      id="filter-select-label"
      class="px-3.5 py-1 text-stone-200 dark:text-neutral-500"
      :size="labelSize"
    >
      {{ $t(label) }}
    </CommonLabel>

    <CommonTab
      v-for="(tab, index) in tabs"
      :id="isTabMode ? `tab-label-${tab.key}` : undefined"
      :key="tab.key"
      ref="tabs"
      :role="isTabMode ? 'tab' : 'option'"
      :aria-controls="isTabMode ? `tab-panel-${tab.key}` : undefined"
      :aria-labelledby="label && !isTabMode ? 'filter-select-label' : undefined"
      :aria-selected="isActiveTab(tab)"
      :active="isActiveTab(tab)"
      :size="size"
      :disabled="tab.disabled"
      :tab-mode="isTabMode"
      :label="tab.label"
      :icon="tab.icon"
      :tooltip="tab.tooltip"
      :count="tab.count"
      tabindex="0"
      class="relative z-10"
      @click="updateModelValue(tab, index)"
      @keydown.enter.prevent="updateModelValue(tab, index)"
      @keydown.space.prevent="updateModelValue(tab, index)"
    />

    <div
      v-if="!multiple"
      ref="marker"
      class="absolute rounded-full bg-white transition-all dark:bg-gray-200"
    />
  </div>
</template>
