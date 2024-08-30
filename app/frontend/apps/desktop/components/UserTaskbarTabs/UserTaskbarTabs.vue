<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { animations, parents } from '@formkit/drag-and-drop'
import { dragAndDrop } from '@formkit/drag-and-drop/vue'
import { cloneDeep } from 'lodash-es'
import { storeToRefs } from 'pinia'
import { ref, watch } from 'vue'

import CommonPopover from '#shared/components/CommonPopover/CommonPopover.vue'
import { usePopover } from '#shared/components/CommonPopover/usePopover.ts'
import { EnumTaskbarEntityAccess } from '#shared/graphql/types.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import { startAndEndEventsDNDPlugin } from '#shared/utils/startAndEndEventsDNDPlugin.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
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
  taskbarTabList,
  taskbarTabListByTabEntityKey,
  taskbarTabListOrder,
  hasTaskbarTabs,
  activeTaskbarTabEntityKey,
  activeTaskbarTabContext,
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

const dndParentRef = ref()
const dndTaskbarTabListOrder = ref(taskbarTabListOrder.value || [])

watch(taskbarTabListOrder, (newValue) => {
  dndTaskbarTabListOrder.value = cloneDeep(newValue || [])
})

dragAndDrop({
  parent: dndParentRef,
  values: dndTaskbarTabListOrder,
  plugins: [
    startAndEndEventsDNDPlugin(dndStartCallback, dndEndCallback),
    animations(),
  ],
  dropZoneClass: 'opacity-0 no-tooltip dragging-active',
  touchDropZoneClass: 'opacity-0 no-tooltip dragging-active',
  draggingClass: 'dragging-active',
})

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

  if (
    taskbarTab.entityAccess === EnumTaskbarEntityAccess.Forbidden ||
    taskbarTab.entityAccess === EnumTaskbarEntityAccess.NotFound
  )
    return

  const plugin = getTaskbarTabTypePlugin(taskbarTab.type)
  if (typeof plugin.buildTaskbarTabLink !== 'function') return

  return plugin.buildTaskbarTabLink(taskbarTab.entity) ?? '#'
}

const { popover, popoverTarget, toggle, isOpen: popoverIsOpen } = usePopover()
</script>

<template>
  <CommonLoader :loading="loading">
    <div
      v-if="hasTaskbarTabs"
      class="-m-1 flex flex-col overflow-y-hidden py-2"
    >
      <div v-if="props.collapsed" class="flex justify-center">
        <CommonPopover
          id="user-taskbar-tabs-popover"
          ref="popover"
          class="min-w-52 max-w-64"
          :owner="popoverTarget"
          orientation="autoHorizontal"
          placement="start"
          hide-arrow
          persistent
        >
          <ul>
            <li
              v-for="userTaskbarTab in taskbarTabList"
              :key="userTaskbarTab.tabEntityKey"
              class="group/tab relative"
            >
              <component
                :is="getTaskbarTabComponent(userTaskbarTab.tabEntityKey)"
                :entity="userTaskbarTab.entity"
                :context="
                  activeTaskbarTabEntityKey === userTaskbarTab.tabEntityKey
                    ? activeTaskbarTabContext
                    : undefined
                "
                :taskbar-tab="userTaskbarTab"
                :taskbar-tab-link="
                  getTaskbarTabLink(userTaskbarTab.tabEntityKey)
                "
                class="group/link rounded-none focus-visible:bg-blue-800 focus-visible:outline-0 group-first/tab:rounded-t-[10px] group-last/tab:rounded-b-[10px]"
              />

              <UserTaskbarTabRemove
                :taskbar-tab-id="userTaskbarTab.taskbarTabId"
                :dirty="
                  activeTaskbarTabEntityKey === userTaskbarTab.tabEntityKey
                    ? (activeTaskbarTabContext.formIsDirty ??
                      userTaskbarTab.dirty)
                    : userTaskbarTab.dirty
                "
                :plugin="getTaskbarTabTypePlugin(userTaskbarTab.type)"
              />
            </li>
          </ul>
        </CommonPopover>

        <CommonButton
          id="user-taskbar-tabs-popover-button"
          ref="popoverTarget"
          class="text-neutral-400 hover:outline-blue-900"
          icon="card-list"
          size="medium"
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
        <CommonLabel
          v-if="!props.collapsed"
          class="mb-2 px-2 text-neutral-500"
          size="small"
        >
          {{ $t('Tabs') }}
        </CommonLabel>

        <span id="drag-and-drop-taskbar-tabs" class="sr-only">
          {{ $t('Drag and drop to reorder your tabs.') }}
        </span>

        <ul
          ref="dndParentRef"
          class="flex flex-col gap-1.5 overflow-y-auto p-1"
          data-theme="dark"
          :style="{ colorScheme: 'dark' }"
        >
          <li
            v-for="tabEntityKey in dndTaskbarTabListOrder"
            :key="tabEntityKey"
            class="draggable group/tab relative"
            draggable="true"
            aria-describedby="drag-and-drop-taskbar-tabs"
          >
            <component
              :is="getTaskbarTabComponent(tabEntityKey)"
              :entity="taskbarTabListByTabEntityKey[tabEntityKey].entity"
              :context="
                activeTaskbarTabEntityKey === tabEntityKey
                  ? activeTaskbarTabContext
                  : undefined
              "
              :taskbar-tab="taskbarTabListByTabEntityKey[tabEntityKey]"
              :taskbar-tab-link="getTaskbarTabLink(tabEntityKey)"
              class="active:cursor-grabbing"
            />

            <UserTaskbarTabRemove
              :taskbar-tab-id="
                taskbarTabListByTabEntityKey[tabEntityKey].taskbarTabId
              "
              :dirty="
                activeTaskbarTabEntityKey === tabEntityKey
                  ? (activeTaskbarTabContext.formIsDirty ??
                    taskbarTabListByTabEntityKey[tabEntityKey].dirty)
                  : taskbarTabListByTabEntityKey[tabEntityKey].dirty
              "
              :plugin="
                getTaskbarTabTypePlugin(
                  taskbarTabListByTabEntityKey[tabEntityKey].type,
                )
              "
            />
          </li>
        </ul>
      </template>
    </div>
  </CommonLoader>
</template>
