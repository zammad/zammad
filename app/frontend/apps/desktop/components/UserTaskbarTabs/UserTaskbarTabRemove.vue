<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'

import { useTouchDevice } from '#shared/composables/useTouchDevice.ts'
import { useWalker } from '#shared/router/walker.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import { useUserCurrentTaskbarTabsStore } from '#desktop/entities/user/current/stores/taskbarTabs.ts'

import type { UserTaskbarTab, UserTaskbarTabPlugin } from './types.ts'

interface Props {
  taskbarTab: UserTaskbarTab
  dirty?: boolean
  plugin?: UserTaskbarTabPlugin
}

const props = defineProps<Props>()

const taskbarTabStore = useUserCurrentTaskbarTabsStore()

const { activeTaskbarTabEntityKey } = storeToRefs(taskbarTabStore)

const { isTouchDevice } = useTouchDevice()

const walker = useWalker()

const confirmRemoveUserTaskbarTab = async () => {
  if (!props.taskbarTab.taskbarTabId) return

  if (
    typeof props.plugin?.confirmTabRemove === 'function' &&
    !(await props.plugin?.confirmTabRemove(props.dirty))
  )
    return

  // In case the tab is currently active, go back to previous route in the history stack.
  if (props.taskbarTab.tabEntityKey === activeTaskbarTabEntityKey.value)
    // TODO: Adjust the following redirect fallback to Overviews page instead, when ready.
    walker.back('/')

  taskbarTabStore.deleteTaskbarTab(props.taskbarTab.taskbarTabId)
}
</script>

<template>
  <CommonButton
    v-if="props.taskbarTab.taskbarTabId"
    v-tooltip="$t('Close this tab')"
    :class="{ 'opacity-0 transition-opacity': !isTouchDevice }"
    class="absolute end-2 top-3 focus:opacity-100 group-hover/tab:opacity-100"
    icon="x-lg"
    size="small"
    variant="remove"
    @click.stop="confirmRemoveUserTaskbarTab"
  />
</template>

<style scoped>
.dragging-active button {
  @apply invisible;
}
</style>
