<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref, watch } from 'vue'

import CommonTab from '#desktop/components/CommonTabs/CommonTabGroup/CommonTab.vue'
import TabsOverflowMenu from '#desktop/components/CommonTabs/TabsOverflowMenu.vue'
import TabsScrollList from '#desktop/components/CommonTabs/TabsScrollList.vue'
import type { Tab } from '#desktop/components/CommonTabs/types.ts'

interface Props {
  multiple?: boolean
  label?: string
  tabs: Tab[]
  size?: 'small' | 'medium' | 'large'
  modelValue?: Tab['key'] | Tab['key'][]
  mode?: 'scroll' | 'overflow'
  /**
   * Single-select only: when nothing is selected, select (and emit) the `default`
   * tab, or the first one. Off by default so the group can also represent an empty
   * selection (e.g. toggle-button form fields).
   */
  selectFirstByDefault?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  size: 'large',
  mode: 'scroll',
})

const emit = defineEmits<{
  'update:modelValue': [value: Tab['key'] | Tab['key'][] | undefined]
}>()

// Local copy so the group reflects its own selection even without a parent v-model,
// and so we can re-emit the current value (see the mount emit below).
const selection = ref<Tab['key'] | Tab['key'][] | undefined>(props.modelValue)
watch(
  () => props.modelValue,
  (value) => {
    selection.value = value
  },
)

const setSelection = (value: Tab['key'] | Tab['key'][] | undefined) => {
  selection.value = value
  emit('update:modelValue', value)
}

const role = computed(() => (props.multiple ? 'listbox' : 'tablist'))

const defaultTabIndex = computed(() => props.tabs.findIndex((tab) => tab.default))

// In single mode a tab is always shown active: the explicit `default` tab, or the first one.
const fallbackTabKey = computed(() => props.tabs[Math.max(defaultTabIndex.value, 0)]?.key)

const activeTabs = computed<Tab['key'][]>(() => {
  const selected = Array.isArray(selection.value)
    ? selection.value
    : selection.value == null
      ? []
      : [selection.value]

  if (props.selectFirstByDefault && !props.multiple && selected.length === 0) {
    return fallbackTabKey.value ? [fallbackTabKey.value] : []
  }

  return selected
})

const updateModelValue = (tab: Tab) => {
  if (tab.disabled) return

  if (!props.multiple) {
    setSelection(tab.key)
    return
  }

  const updatedTabs = activeTabs.value.includes(tab.key)
    ? activeTabs.value.filter((activeTab) => activeTab !== tab.key)
    : [...activeTabs.value, tab.key]

  setSelection(updatedTabs as Tab['key'][])
}

// On mount (single mode), echo the resolved selection to the parent so consumers that
// derive state from the *emitted* value — not just the prop — initialize correctly
// (e.g. FieldSecurity bootstrapping its default options). When nothing is selected we
// only emit the default/first tab if the consumer opted in via `selectFirstByDefault`.
if (!props.multiple) {
  if (selection.value != null) {
    setSelection(selection.value)
  } else if (props.selectFirstByDefault && fallbackTabKey.value) {
    setSelection(fallbackTabKey.value)
  }
}

const isOverflowMode = computed(() => props.mode === 'overflow')

const appearanceStyling = computed(() => (isOverflowMode.value ? 'rounded-lg' : 'rounded-full'))
</script>

<template>
  <div
    class="relative flex w-full max-w-full min-w-0 bg-blue-200 p-1 @lg:w-fit dark:bg-gray-700"
    :class="appearanceStyling"
  >
    <TabsOverflowMenu
      v-if="isOverflowMode"
      :tabs="tabs"
      :active-keys="activeTabs"
      :label="label"
      :multiple="multiple"
      :container-role="role"
      list-item-role="presentation"
    >
      <template #default="{ tab, active, tabClass, tabActiveClass }">
        <CommonTab
          :id="multiple ? undefined : `tab-label-${tab.key}`"
          v-tooltip="tab.tooltip"
          v-bind="tab"
          :class="[tabClass, { [tabActiveClass]: active }]"
          :tab-id="tab.key"
          :size="size"
          :active-keys="activeTabs"
          :multiple="multiple"
          @select="updateModelValue(tab)"
        />
      </template>

      <template #overflow-item="{ tab, close, active, itemClass, itemActiveClass }">
        <CommonTab
          :id="multiple ? undefined : `tab-label-${tab.key}`"
          v-tooltip="tab.tooltip"
          v-bind="tab"
          :class="[itemClass, { [itemActiveClass]: active }]"
          :tab-id="tab.key"
          :size="size"
          :active-keys="activeTabs"
          :multiple="multiple"
          @select="
            () => {
              updateModelValue(tab)
              close()
            }
          "
        />
      </template>
    </TabsOverflowMenu>

    <TabsScrollList
      v-else
      :tabs="tabs"
      :active-keys="activeTabs"
      :multiple="multiple"
      :label="label"
      :container-role="role"
      list-item-role="presentation"
    >
      <template #default="{ tab, tabClass, canDisplayIconOnly }">
        <CommonTab
          :id="multiple ? undefined : `tab-label-${tab.key}`"
          v-tooltip="tab.tooltip"
          class="flex justify-center @lg:justify-start"
          v-bind="tab"
          :class="tabClass"
          :tab-id="tab.key"
          :size="size"
          :can-display-icon-only="canDisplayIconOnly"
          :active-keys="activeTabs"
          :multiple="multiple"
          @select="updateModelValue(tab)"
        />
      </template>
    </TabsScrollList>
  </div>
</template>
