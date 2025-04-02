<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { animations, parents, updateConfig } from '@formkit/drag-and-drop'
import { dragAndDrop } from '@formkit/drag-and-drop/vue'
import { computedAsync } from '@vueuse/core'
import { cloneDeep } from 'lodash-es'
import { storeToRefs } from 'pinia'
import { type Ref, ref, watch, useTemplateRef, nextTick } from 'vue'

import CommonPopover from '#shared/components/CommonPopover/CommonPopover.vue'
import { usePopover } from '#shared/components/CommonPopover/usePopover.ts'
import { EnumTaskbarEntityAccess } from '#shared/graphql/types.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import { startAndEndEventsDNDPlugin } from '#shared/utils/startAndEndEventsDNDPlugin.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import CommonSectionCollapse from '#desktop/components/CommonSectionCollapse/CommonSectionCollapse.vue'
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

watch(taskbarTabListOrder, (newValue) => {
  dndTaskbarTabListOrder.value = cloneDeep(newValue || [])
})

dragAndDrop({
  parent: dndParentElement as Ref<HTMLElement>,
  values: dndTaskbarTabListOrder,
  plugins: [
    startAndEndEventsDNDPlugin(dndStartCallback, dndEndCallback),
    animations(),
  ],
  dropZoneClass: 'opacity-0 no-tooltip dragging-active',
  touchDropZoneClass: 'opacity-0 no-tooltip dragging-active',
  draggingClass: 'dragging-active',
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

  if (
    !taskbarTab.entityAccess ||
    taskbarTab.entityAccess === EnumTaskbarEntityAccess.Granted
  )
    return getTaskbarTabTypePlugin(taskbarTab.type).component

  if (taskbarTab.entityAccess === EnumTaskbarEntityAccess.Forbidden)
    return UserTaskbarTabForbidden

  if (taskbarTab.entityAccess === EnumTaskbarEntityAccess.NotFound)
    return UserTaskbarTabNotFound
}

const getTaskbarTabLink = (tabEntityKey: string) => {
  const taskbarTab = taskbarTabListByTabEntityKey.value[tabEntityKey]

  if (!taskbarTab) return

  const plugin = getTaskbarTabTypePlugin(taskbarTab.type)
  if (typeof plugin.buildTaskbarTabLink !== 'function') return

  return (
    plugin.buildTaskbarTabLink(taskbarTab.entity, taskbarTab.tabEntityKey) ??
    '#'
  )
}

const { popover, popoverTarget, toggle, isOpen: popoverIsOpen } = usePopover()

const taskbarTabListContainer = useTemplateRef('taskbar-tab-list')

const taskbarTabListLocation = computedAsync(() => {
  if (!taskbarTabListContainer.value) return '#taskbarTabListHidden'

  // NB: Prevent teleport component from complaining that the target is not ready.
  //   Defer the value update for after next tick.
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
</script>

<template>
  <CommonLoader no-transition :loading="loading">
    <div
      v-if="hasTaskbarTabs"
      class="-m-1 flex flex-col overflow-y-hidden py-2"
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
          :aria-controls="
            popoverIsOpen ? 'user-taskbar-tabs-popover' : undefined
          "
          aria-haspopup="true"
          :aria-expanded="popoverIsOpen"
          :aria-label="$t('List of all user taskbar tabs')"
          :class="{
            '!bg-blue-800 !text-white': popoverIsOpen,
          }"
          @click="toggle(true)"
        />
      </div>

      <template v-else>
        <CommonSectionCollapse
          id="user-taskbar-tabs"
          :title="__('Tabs')"
          no-negative-margin
          scrollable
        >
          <span id="drag-and-drop-taskbar-tabs" class="sr-only">
            {{ $t('Drag and drop to reorder your tabs.') }}
          </span>

          <div id="taskbarTabListExpanded" ref="taskbar-tab-list" />
        </CommonSectionCollapse>
      </template>

      <div id="taskbarTabListHidden" class="hidden" aria-hidden="true">
        <Teleport :to="taskbarTabListLocation" defer>
          <ul
            ref="dnd-parent"
            :class="{ 'flex flex-col gap-1.5 overflow-y-auto p-1': !collapsed }"
          >
            <li
              v-for="tabEntityKey in dndTaskbarTabListOrder"
              :key="tabEntityKey"
              class="group/tab relative"
              :class="{ draggable: !collapsed }"
              :draggable="!collapsed ? 'true' : undefined"
              :aria-describedby="
                !collapsed ? 'drag-and-drop-taskbar-tabs' : undefined
              "
            >
              <component
                :is="getTaskbarTabComponent(tabEntityKey)"
                :context="getTaskbarTabContext(tabEntityKey)"
                :taskbar-tab="taskbarTabListByTabEntityKey[tabEntityKey]"
                :taskbar-tab-link="getTaskbarTabLink(tabEntityKey)"
                :class="{
                  'group/link rounded-none group-first/tab:rounded-t-[10px] group-last/tab:rounded-b-[10px] focus-visible:bg-blue-800 focus-visible:outline-0':
                    collapsed,
                  'active:cursor-grabbing': !collapsed,
                }"
              />

              <UserTaskbarTabRemove
                :taskbar-tab="taskbarTabListByTabEntityKey[tabEntityKey]"
                :dirty="getTaskbarTabDirtyFlag(tabEntityKey)"
                :plugin="
                  getTaskbarTabTypePlugin(
                    taskbarTabListByTabEntityKey[tabEntityKey].type,
                  )
                "
              />
            </li>
          </ul>
        </Teleport>
      </div>
    </div>
  </CommonLoader>
</template>
