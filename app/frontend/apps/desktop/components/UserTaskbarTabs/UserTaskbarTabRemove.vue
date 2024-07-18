<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useRouter } from 'vue-router'

import { useTouchDevice } from '#shared/composables/useTouchDevice.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import { useUserCurrentTaskbarTabsStore } from '#desktop/entities/user/current/stores/taskbarTabs.ts'

import type { UserTaskbarTabPlugin } from './types'

interface Props {
  taskbarTabId?: ID
  dirty?: boolean
  plugin?: UserTaskbarTabPlugin
}

const props = defineProps<Props>()

const router = useRouter()

const taskbarTabStore = useUserCurrentTaskbarTabsStore()

const { isTouchDevice } = useTouchDevice()

const confirmRemoveUserTaskbarTab = async () => {
  if (!props.taskbarTabId) return

  if (
    typeof props.plugin?.confirmTabRemove === 'function' &&
    !(await props.plugin?.confirmTabRemove(props.dirty))
  )
    return

  taskbarTabStore.deleteTaskbarTab(props.taskbarTabId)

  // TODO: Check if the tab is the current active tab, if yes, redirect to ... ?!
  router.push('/dashboard')
}
</script>

<template>
  <CommonButton
    v-if="props.taskbarTabId"
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
