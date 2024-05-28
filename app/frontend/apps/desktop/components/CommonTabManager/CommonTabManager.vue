<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, nextTick, onMounted, ref } from 'vue'

import CommonTab from '#desktop/components/CommonTabManager/CommonTab.vue'
import type { Tab } from '#desktop/components/CommonTabManager/types.ts'

interface Props {
  multiple?: boolean
  label?: string
  tabs: Tab[]
  modelValue?: Tab[] | Tab['key']
}

const props = defineProps<Props>()

const tabNodes = ref<InstanceType<typeof CommonTab>[]>()

const emit = defineEmits<{
  'update:modelValue': [unknown]
}>()

const isTabMode = computed(() => !props.multiple)

const activeTabIndex = computed(() => {
  return props.tabs.findIndex(
    (tab) => tab.key === (props.modelValue as Tab['key']),
  )
})

const activeTabWidth = computed(() => {
  return tabNodes.value?.at(activeTabIndex.value)?.$el.offsetWidth || 0
})

const activeTabHeight = computed(() => {
  return tabNodes.value?.at(activeTabIndex.value)?.$el.offsetHeight || 0
})

const activeTabOffsetLeft = computed(() => {
  return tabNodes.value?.at(activeTabIndex.value)?.$el.offsetLeft || 0
})

// Functions are invoked only if multiple is true
const removeActiveTab = (tab: Tab) => {
  return (props.modelValue as Tab[])?.filter(
    (activeTab) => activeTab?.key !== tab.key,
  )
}

const addActiveTab = (tab: Tab) => {
  // Initial modelValue could be falsy
  if (props.modelValue) return [...(props.modelValue as Tab[]), tab]
  return [tab]
}

const updateModelValue = (tab: Tab) => {
  if (!props.multiple) return emit('update:modelValue', tab.key)

  // If tab is already included, remove it, otherwise add it
  return (props.modelValue as Tab[])?.some(
    (activeTab) => activeTab.label === tab.label,
  )
    ? emit('update:modelValue', removeActiveTab(tab))
    : emit('update:modelValue', addActiveTab(tab))
}

onMounted(() => {
  if (props.multiple) return

  nextTick(() => {
    const defaultTabIndex = props.tabs.findIndex((tab) => tab.default)

    if (defaultTabIndex === -1) return updateModelValue(props.tabs[0])

    updateModelValue(props.tabs[defaultTabIndex])
  })
})
</script>

<template>
  <div
    :role="isTabMode ? 'tablist' : 'listbox'"
    class="relative flex w-fit items-center gap-1 rounded-full bg-blue-200 p-1 dark:bg-gray-700"
  >
    <CommonTab v-if="label" id="filter-select-label">
      <CommonLabel class="text-stone-200 dark:text-neutral-500" size="medium">{{
        $t(label)
      }}</CommonLabel>
    </CommonTab>

    <CommonTab
      v-if="!multiple"
      :style="{
        width: activeTabWidth + 'px',
        left: activeTabOffsetLeft + 'px',
        height: activeTabHeight + 'px',
      }"
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
      class="relative z-10 cursor-pointer"
      :no-active-background="isTabMode"
      :aria-labelledby="label && !isTabMode ? 'filter-select-label' : undefined"
      :aria-selected="
        Array.isArray(modelValue)
          ? modelValue?.some((activeTab) => activeTab.key === tab.key)
          : modelValue === tab.key
      "
      :active="
        Array.isArray(modelValue)
          ? modelValue?.some((activeTab) => activeTab.key === tab.key)
          : modelValue === tab.key
      "
      @click="updateModelValue(tab)"
      @keydown.enter="updateModelValue(tab)"
      >{{ $t(tab.label) }}
    </CommonTab>
  </div>
</template>
