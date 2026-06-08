<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { parents } from '@formkit/drag-and-drop'
import { cloneDeep, isEqual } from 'lodash-es'
import { watch, useTemplateRef, shallowRef } from 'vue'

import { useAnnouncer } from '#desktop/composables/accessibility/useAnnouncer.ts'
import { useAccessibleDragAndDrop } from '#desktop/composables/dragAndDrop/useAccessibleDragAndDrop.ts'
import { useKeyboardKeysForDragAndDrop } from '#desktop/composables/dragAndDrop/useKeyboardKeysForDragAndDrop.ts'

export interface OverviewItem {
  id: string
  name: string
  organizationShared?: boolean | null
  outOfOffice?: boolean | null
}

const localValue = defineModel<OverviewItem[]>({
  required: true,
})

const dndEndCallback = (parent: HTMLElement) => {
  const parentData = parents.get(parent)
  if (!parentData) return

  localValue.value = cloneDeep(parentData.getValues(parent))
}

const dndParentElement = useTemplateRef('dnd-parent')
const dndLocalValue = shallowRef<OverviewItem[]>(localValue.value || [])

watch(localValue, (newValue) => {
  if (isEqual(dndLocalValue.value, newValue)) return

  dndLocalValue.value = cloneDeep(newValue || [])
})

const { announce, messageNodeId } = useAnnouncer()

const getValue = (item: OverviewItem) => item.name

useAccessibleDragAndDrop<HTMLElement, OverviewItem>(dndParentElement, dndLocalValue, announce, {
  dndEndCallback,
  getValue,
})

const {
  focusedItemIndex,
  selectedItemIndex,
  focusedItemId,
  handleKeydown,
  handleFocus,
  handleBlur,
} = useKeyboardKeysForDragAndDrop<OverviewItem>({
  items: dndLocalValue,
  getValue,
  onReorder: (newOrder) => {
    localValue.value = cloneDeep(newOrder)
  },
})
</script>

<template>
  <div v-if="localValue" class="rounded-lg bg-blue-200 dark:bg-gray-700">
    <!--   eslint-disable vuejs-accessibility/no-static-element-interactions       -->
    <ul
      ref="dnd-parent"
      tabindex="0"
      :aria-label="$t('Overview order list')"
      :aria-activedescendant="focusedItemId"
      :aria-describedby="messageNodeId"
      class="group isolate flex flex-col rounded-lg p-1 focus-visible-app-default focus-visible:-outline-offset-1!"
      @focus="handleFocus"
      @blur="handleBlur"
      @keydown="handleKeydown"
    >
      <li
        v-for="(value, index) in dndLocalValue"
        :key="value.id"
        class="draggable flex min-h-9 cursor-grab items-start gap-2.5 rounded-lg p-2.5 active:cursor-grabbing"
        draggable="true"
        :class="{
          '-outline-offset-1 outline-blue-900 group-focus-visible:outline':
            index == focusedItemIndex,
          'outline -outline-offset-1 outline-blue-800!': index == selectedItemIndex,
        }"
      >
        <CommonIcon
          class="mt-1 shrink-0 fill-stone-200 dark:fill-neutral-500"
          name="grip-vertical"
          size="tiny"
          decorative
        />
        <div class="grow">
          <CommonLabel class="inline text-black dark:text-white">
            {{ $t(value.name) }}
          </CommonLabel>
          <CommonBadge v-if="value.organizationShared" variant="info" class="ms-1.5">{{
            $t('Only when shared organization member')
          }}</CommonBadge>
          <CommonBadge v-if="value.outOfOffice" variant="info" class="ms-1.5">{{
            $t('Only when out of office replacement')
          }}</CommonBadge>
        </div>
      </li>
    </ul>
  </div>
</template>
