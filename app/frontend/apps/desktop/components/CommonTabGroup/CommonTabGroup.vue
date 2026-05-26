<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useResizeObserver } from '@vueuse/core'
import { computed, ref, useTemplateRef, watch } from 'vue'

import getUuid from '#shared/utils/getUuid.ts'

import CommonTab from '#desktop/components/CommonTabGroup/CommonTab.vue'
import type { MarkerStyle, Tab } from '#desktop/components/CommonTabGroup/types.ts'
import { useKeepAliveHooks } from '#desktop/composables/useKeepAliveHooks.ts'

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
const tabInstances = useTemplateRef('tabs')

const isTabMode = computed(() => !props.multiple)
const labelSize = computed(() => (props.size === 'large' ? 'medium' : 'small'))

const defaultTabIndex = computed(() => props.tabs.findIndex((tab) => tab.default))

const selectedIndex = computed<number | null>(() => {
  if (props.multiple) return null

  const activeTabKey = props.modelValue
  const activeTabIndex = props.tabs.findIndex((tab) => activeTabKey === tab.key)

  return activeTabIndex === -1 ? defaultTabIndex.value : activeTabIndex
})

const activeTabs = computed(() =>
  Array.isArray(props.modelValue) ? props.modelValue : [props.modelValue],
)

const isActiveTab = (tab: Tab) => activeTabs.value.includes(tab.key)

const markerStyle = ref<MarkerStyle | null>(null)
const transitionsEnabled = ref(false)

const measureMarker = () => {
  const index = selectedIndex.value ?? defaultTabIndex.value

  if (index == null || index < 0) {
    markerStyle.value = null
    return
  }

  const tabElement = tabInstances.value?.at(index)

  if (!tabElement) {
    markerStyle.value = null
    return
  }

  const el = tabElement.$el as HTMLElement
  markerStyle.value = {
    top: `${el.offsetTop}px`,
    left: `${el.offsetLeft}px`,
    width: `${el.offsetWidth}px`,
    height: `${el.offsetHeight}px`,
  }
}

// We don't apply transition before we have the calculation
// to prevent this flash of transition initially
const enableTransitionsAfterPaint = () => {
  requestAnimationFrame(() => {
    requestAnimationFrame(() => {
      transitionsEnabled.value = true
    })
  })
}

const updateModelValue = (tab: Tab) => {
  if (tab.disabled) return

  if (!props.multiple) return emit('update:modelValue', tab.key)

  const updatedTabs = activeTabs.value.includes(tab.key)
    ? activeTabs.value.filter((activeTab) => activeTab !== tab.key)
    : [...activeTabs.value, tab.key]

  emit('update:modelValue', updatedTabs as Tab['key'][])
}

if (!props.multiple) {
  const initialTabIndex = props.modelValue
    ? props.tabs.findIndex((tab) => activeTabs.value.includes(tab.key))
    : defaultTabIndex.value

  if (initialTabIndex === -1) updateModelValue(props.tabs[0])
  else updateModelValue(props.tabs[initialTabIndex])
}

const stopWatcher = watch(selectedIndex, measureMarker, { flush: 'post' })
if (props.multiple) stopWatcher()

useResizeObserver(containerElement, measureMarker)

useKeepAliveHooks({
  onInitialActivated() {
    measureMarker()
    enableTransitionsAfterPaint()
  },
  onReactivated() {
    transitionsEnabled.value = false

    measureMarker()
    enableTransitionsAfterPaint()
  },
})

const labelId = getUuid()
</script>

<template>
  <div
    ref="container"
    :role="isTabMode ? 'tablist' : 'listbox'"
    :aria-labelledby="label ? labelId : undefined"
    class="relative flex w-fit items-center gap-1 rounded-full bg-blue-200 p-1 dark:bg-gray-700"
  >
    <CommonLabel
      v-if="label"
      :id="labelId"
      class="px-3.5 py-1 text-stone-200 dark:text-neutral-500"
      :size="labelSize"
    >
      {{ $t(label) }}
    </CommonLabel>

    <CommonTab
      v-for="tab in tabs"
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
      @click="updateModelValue(tab)"
      @keydown.enter.prevent="updateModelValue(tab)"
      @keydown.space.prevent="updateModelValue(tab)"
    />

    <div
      v-if="!multiple"
      class="absolute rounded-full bg-white dark:bg-gray-200"
      :class="{
        'transition-all': transitionsEnabled,
        invisible: !markerStyle,
      }"
      :style="markerStyle"
    />
  </div>
</template>
