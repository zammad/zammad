<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { parents, updateConfig } from '@formkit/drag-and-drop'
import { computedAsync } from '@vueuse/core'
import { cloneDeep } from 'lodash-es'
import { storeToRefs } from 'pinia'
import { ref, watch, useTemplateRef, nextTick } from 'vue'

import { useTouchDevice } from '#shared/composables/useTouchDevice.ts'
import { EnumTaskbarEntityAccess } from '#shared/graphql/types.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import CommonPopover from '#desktop/components/CommonPopover/CommonPopover.vue'
import { usePopover } from '#desktop/components/CommonPopover/usePopover.ts'
import CommonSectionCollapse from '#desktop/components/CommonSectionCollapse/CommonSectionCollapse.vue'
import { useAnnouncer } from '#desktop/composables/accessibility/useAnnouncer.ts'
import { useAccessibleDragAndDrop } from '#desktop/composables/dragAndDrop/useAccessibleDragAndDrop.ts'
import { useKeyboardKeysForDragAndDrop } from '#desktop/composables/dragAndDrop/useKeyboardKeysForDragAndDrop.ts'
import { useUserCurrentTaskbarItemListPrioMutation } from '#desktop/entities/user/current/graphql/mutations/userCurrentTaskbarItemListPrio.api.ts'
import { useUserCurrentTaskbarTabsStore } from '#desktop/entities/user/current/stores/taskbarTabs.ts'

import UserTaskbarTabForbidden from './UserTaskbarTabForbidden.vue'
import UserTaskbarTabNotFound from './UserTaskbarTabNotFound.vue'
import UserTaskbarTabRemove from './UserTaskbarTabRemove.vue'

export interface Props {
  collapsed?: boolean
}

const props = defineProps<Props>()

const taskbarTabStore = useUserCurrentTaskbarTabsStore()

const {
  taskbarTabListByTabEntityKey,
  taskbarTabListOrder,
  hasTaskbarTabs,
  taskbarTabContexts,
  loading,
} = storeToRefs(taskbarTabStore)

const { getTaskbarTabTypePlugin } = taskbarTabStore

const dndStartCallback = (parent: HTMLElement) => {
  const siblings = parent.querySelectorAll('.draggable:not(.dragging-active)')

  // Temporarily suspend tab hover states.
  siblings.forEach((sibling) => {
    sibling.classList.remove('group/tab')
    sibling.classList.add('no-tooltip')
  })
}

const userCurrentTaskbarItemListPrioMutation = new MutationHandler(
  useUserCurrentTaskbarItemListPrioMutation(),
)

const updateTaskbarTabListOrder = (newTaskbarTabListOrder: string[]) => {
  const taskbarTabListPrio = newTaskbarTabListOrder
    ?.map((tabEntityKey, index) => ({
      id: taskbarTabListByTabEntityKey.value[tabEntityKey].taskbarTabId!,
      prio: index + 1,
    }))
    .filter((taskbarTabListPrioItem) => taskbarTabListPrioItem.id)

  if (!taskbarTabListPrio?.length) return

  userCurrentTaskbarItemListPrioMutation.send({
    list: taskbarTabListPrio,
  })
}

const dndEndCallback = (parent: HTMLElement) => {
  const parentData = parents.get(parent)

  if (parentData) {
    updateTaskbarTabListOrder(parentData.getValues(parent))
  }

  const siblings = parent.querySelectorAll('.draggable:not(.dragging-active)')

  // Reactivate tab hover states.
  siblings.forEach((sibling) => {
    sibling.classList.add('group/tab')
    sibling.classList.remove('no-tooltip')
  })

  // NB: Workaround for a Chrome bug where the hover state may get stuck once drag is over.
  //   https://issues.chromium.org/issues/41129937#comment6
  setTimeout(() => {
    parent.classList.add('pointer-events-none')
    requestAnimationFrame(() => {
      parent.classList.remove('pointer-events-none')
    })
  }, 0)
}

const dndParentElement = useTemplateRef('dnd-parent')
const dndTaskbarTabListOrder = ref(taskbarTabListOrder.value || [])
let isKeyboardReorder = false

watch(taskbarTabListOrder, (newValue) => {
  if (!isKeyboardReorder) {
    dndTaskbarTabListOrder.value = cloneDeep(newValue || [])
  }
  // Reset flag after store update
  isKeyboardReorder = false
})

const { messageNodeId } = useAnnouncer()

const {
  focusedItemIndex,
  selectedItemIndex,
  focusedItemId,
  handleKeydown,
  handleFocus,
  handleBlur,
} = useKeyboardKeysForDragAndDrop({
  items: dndTaskbarTabListOrder,
  onReorder: (newOrder) => {
    isKeyboardReorder = true
    updateTaskbarTabListOrder(newOrder)
  },
})

useAccessibleDragAndDrop(dndParentElement, dndTaskbarTabListOrder, {
  dropZoneClass: 'no-tooltip',
  synthDropZoneClass: 'no-tooltip',
  dndStartCallback,
  dndEndCallback,
})

watch(
  () => props.collapsed,
  (isCollapsed) => {
    if (!dndParentElement.value) return

    updateConfig(dndParentElement.value, { disabled: isCollapsed })
  },
)

const getTaskbarTabComponent = (tabEntityKey: string) => {
  const taskbarTab = taskbarTabListByTabEntityKey.value[tabEntityKey]
  if (!taskbarTab) return

  if (!taskbarTab.entityAccess || taskbarTab.entityAccess === EnumTaskbarEntityAccess.Granted)
    return getTaskbarTabTypePlugin(taskbarTab.type).component

  if (taskbarTab.entityAccess === EnumTaskbarEntityAccess.Forbidden) return UserTaskbarTabForbidden

  if (taskbarTab.entityAccess === EnumTaskbarEntityAccess.NotFound) return UserTaskbarTabNotFound
}

const getTaskbarTabLink = (tabEntityKey: string) => {
  const taskbarTab = taskbarTabListByTabEntityKey.value[tabEntityKey]

  if (!taskbarTab) return

  const plugin = getTaskbarTabTypePlugin(taskbarTab.type)
  if (typeof plugin.buildTaskbarTabLink !== 'function') return

  return plugin.buildTaskbarTabLink(taskbarTab.entity, taskbarTab.tabEntityKey) ?? '#'
}

const { popover, popoverTarget, toggle, isOpen: popoverIsOpen } = usePopover()

const taskbarTabListContainer = useTemplateRef('taskbar-tab-list')

const taskbarTabListLocation = computedAsync(() => {
  if (!taskbarTabListContainer.value) return '#taskbarTabListHidden'

  // NB: Prevent a teleport component from complaining that the target is not ready.
  //   Defer the value update for after the next tick.
  return nextTick(() => {
    if (props.collapsed) return '#taskbarTabListCollapsed'
    return '#taskbarTabListExpanded'
  })
}, '#taskbarTabListHidden')

const getTaskbarTabContext = (tabEntityKey: string) => {
  if (!taskbarTabListContainer.value) return

  return taskbarTabContexts.value[tabEntityKey]
}

const getTaskbarTabDirtyFlag = (tabEntityKey: string) => {
  if (!taskbarTabListContainer.value) return

  return (
    taskbarTabContexts.value[tabEntityKey]?.formIsDirty ??
    taskbarTabListByTabEntityKey.value[tabEntityKey].dirty
  )
}

const { isTouchDevice } = useTouchDevice()
</script>

<template>
  <CommonLoader no-transition :loading="loading">
    <div
      v-if="hasTaskbarTabs"
      class="flex flex-col overflow-y-hidden"
      :class="{ 'py-1': collapsed }"
    >
      <div v-if="props.collapsed" class="flex justify-center">
        <CommonPopover
          id="user-taskbar-tabs-popover"
          ref="popover"
          class="max-w-64 min-w-52"
          :owner="popoverTarget"
          orientation="autoHorizontal"
          placement="start"
          hide-arrow
          persistent
        >
          <div id="taskbarTabListCollapsed" ref="taskbar-tab-list" />
        </CommonPopover>

        <CommonButton
          id="user-taskbar-tabs-popover-button"
          ref="popoverTarget"
          class="text-neutral-400 hover:outline-blue-900"
          icon="card-list"
          size="large"
          variant="neutral"
          :aria-controls="popoverIsOpen ? 'user-taskbar-tabs-popover' : undefined"
          aria-haspopup="true"
          :aria-expanded="popoverIsOpen"
          :aria-label="$t('List of all user taskbar tabs')"
          :class="{
            'bg-blue-800! text-white!': popoverIsOpen,
          }"
          @click="toggle(true)"
        />
      </div>

      <template v-else>
        <CommonSectionCollapse
          id="user-taskbar-tabs"
          class="gap-0! px-2 py-0.5"
          :title="__('Tabs')"
          no-negative-margin
          scrollable
        >
          <div id="taskbarTabListExpanded" ref="taskbar-tab-list" />
        </CommonSectionCollapse>
      </template>

      <div id="taskbarTabListHidden" class="hidden" aria-hidden="true">
        <Teleport :to="taskbarTabListLocation" defer>
          <!--   eslint-disable vuejs-accessibility/no-static-element-interactions       -->
          <ul
            ref="dnd-parent"
            tabindex="0"
            :aria-label="$t('User taskbar tabs')"
            :aria-activedescendant="focusedItemId"
            :aria-describedby="messageNodeId"
            :class="{
              'flex flex-col gap-1.5 overflow-y-auto p-1': !collapsed,
            }"
            class="focus-visible-app-default focus-visible:-outline-offset-1! rounded-lg"
            @focus="handleFocus"
            @blur="handleBlur"
            @keydown="handleKeydown"
          >
            <li
              v-for="(tabEntityKey, index) in dndTaskbarTabListOrder"
              :id="`item-${tabEntityKey}`"
              :key="tabEntityKey"
              class="group/tab relative"
              :class="{
                draggable: !collapsed,
                'overflow-hidden first:rounded-t-lg last:rounded-b-lg': collapsed,
              }"
              :draggable="!collapsed ? 'true' : undefined"
            >
              <UserTaskbarTabRemove
                v-if="taskbarTabListByTabEntityKey[tabEntityKey].taskbarTabId"
                class="peer"
                :taskbar-tab="taskbarTabListByTabEntityKey[tabEntityKey]"
                :dirty="getTaskbarTabDirtyFlag(tabEntityKey)"
                :plugin="getTaskbarTabTypePlugin(taskbarTabListByTabEntityKey[tabEntityKey].type)"
              />

              <component
                :is="getTaskbarTabComponent(tabEntityKey)"
                :context="getTaskbarTabContext(tabEntityKey)"
                :taskbar-tab="taskbarTabListByTabEntityKey[tabEntityKey]"
                :taskbar-tab-link="getTaskbarTabLink(tabEntityKey)"
                :collapsed="collapsed"
                class="group/link peer-focus-visible:trl:pl-(--tab-remove-bar-button-width) focus-visible-app-default [--tab-remove-bar-button-width:2rem] group-hover/tab:ltr:pr-(--tab-remove-bar-button-width) peer-focus-visible:ltr:pr-(--tab-remove-bar-button-width) group-hover/tab:rtl:pl-(--tab-remove-bar-button-width)"
                :class="{
                  'rounded-none group-first/tab:rounded-t-[10px] group-last/tab:rounded-b-[10px] focus-visible:-outline-offset-1!':
                    collapsed,
                  'rounded-t-lg!': collapsed && index === 0,
                  'rounded-b-lg!': collapsed && index === dndTaskbarTabListOrder.length - 1,
                  'active:cursor-grabbing': !collapsed,
                  'ltr:pr-(--tab-remove-bar-button-width) rtl:pl-(--tab-remove-bar-button-width)':
                    isTouchDevice,
                  'outline outline-offset-1 outline-blue-900': index == focusedItemIndex,
                  'outline outline-offset-1 outline-blue-800!': index == selectedItemIndex,
                }"
              />
            </li>
          </ul>
        </Teleport>
      </div>
    </div>
  </CommonLoader>
</template>
