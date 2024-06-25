<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, nextTick, onMounted, ref, watch } from 'vue'

import CommonTab from '#desktop/components/CommonTabManager/CommonTab.vue'
import type { Tab } from '#desktop/components/CommonTabManager/types.ts'

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

const tabNodes = ref<InstanceType<typeof CommonTab>[]>()

const emit = defineEmits<{
  'update:modelValue': [Tab['key'] | Tab['key'][]]
}>()

const isTabMode = computed(() => !props.multiple)

const activeTabIndex = computed(() => {
  return props.tabs.findIndex(
    (tab) => tab.key === (props.modelValue as Tab['key']),
  )
})

const activeTabWidth = ref<number>(0)
const activeTabHeight = ref<number>(0)
const activeTabOffsetLeft = ref<number>(0)

const getElementWidth = (el: HTMLElement) => el.offsetWidth || 0
const getElementHeight = (el: HTMLElement) => el.offsetHeight || 0
const getElementOffsetLeft = (el: HTMLElement) => el.offsetLeft || 0

const isActiveTab = (tab: Tab) =>
  Array.isArray(props.modelValue)
    ? props.modelValue.some((activeTab) => activeTab === tab.key)
    : props.modelValue === tab.key

const refreshActiveTabRefs = (el?: HTMLElement) => {
  if (!el) return

  requestAnimationFrame(() => {
    nextTick(() => {
      activeTabWidth.value = getElementWidth(el)
      activeTabHeight.value = getElementHeight(el)
      activeTabOffsetLeft.value = getElementOffsetLeft(el)
    })
  })
}

const onTabReady = (tab: Tab, el?: HTMLElement) => {
  if (props.multiple || !isActiveTab(tab)) return
  if (!el) return

  refreshActiveTabRefs(el)
}

watch(activeTabIndex, (index) => {
  if (!tabNodes.value) return

  const el = tabNodes.value?.[index].$el
  if (!el) return

  refreshActiveTabRefs(el)
})

const updateModelValue = (tab: Tab) => {
  if (tab.disabled) return
  if (!props.multiple) return emit('update:modelValue', tab.key)

  // If tab is already included, remove it, otherwise add it
  return Array.isArray(props.modelValue) && props.modelValue?.includes(tab.key)
    ? emit(
        'update:modelValue',
        props.modelValue?.filter((activeTab) => activeTab !== tab.key),
      )
    : emit('update:modelValue', [...(props.modelValue || []), tab.key])
}

onMounted(() => {
  if (props.multiple || props.modelValue) return

  nextTick(() => {
    const defaultTabIndex = props.tabs.findIndex((tab) => tab.default)

    if (defaultTabIndex === -1) return updateModelValue(props.tabs[0])

    updateModelValue(props.tabs[defaultTabIndex])
  })
})

const labelSize = computed(() => (props.size === 'large' ? 'medium' : 'small'))
</script>

<template>
  <div
    :role="isTabMode ? 'tablist' : 'listbox'"
    class="relative flex w-fit items-center gap-1 rounded-full bg-blue-200 p-1 dark:bg-gray-700"
  >
    <CommonLabel
      v-if="label"
      id="filter-select-label"
      class="px-3.5 py-1 text-stone-200 dark:text-neutral-500"
      :size="labelSize"
      >{{ $t(label) }}</CommonLabel
    >

    <CommonTab
      v-if="!multiple"
      :style="{
        width: `${activeTabWidth}px`,
        left: `${activeTabOffsetLeft}px`,
        height: `${activeTabHeight}px`,
      }"
      :size="size"
      active
      role="presentation"
      class="absolute z-0 transition-[left]"
    />

    <CommonTab
      v-for="(tab, index) in tabs"
      :id="isTabMode ? `tab-label-${tab.key}` : undefined"
      ref="tabNodes"
      :key="`${tab.key}-${index}`"
      :role="isTabMode ? 'tab' : 'option'"
      :aria-controls="isTabMode ? `tab-panel-${tab.key}` : undefined"
      tabindex="0"
      class="relative z-10"
      :size="size"
      :disabled="tab.disabled"
      :tab-mode="isTabMode"
      :aria-labelledby="label && !isTabMode ? 'filter-select-label' : undefined"
      :aria-selected="isActiveTab(tab)"
      :active="isActiveTab(tab)"
      :label="tab.label"
      :icon="tab.icon"
      :tooltip="tab.tooltip"
      @click="updateModelValue(tab)"
      @keydown.enter.prevent="updateModelValue(tab)"
      @keydown.space.prevent="updateModelValue(tab)"
      @ready="onTabReady(tab, $event)"
    />
  </div>
</template>
