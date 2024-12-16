<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { useRouter } from 'vue-router'

import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import { useTouchDevice } from '#shared/composables/useTouchDevice.ts'

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

const router = useRouter()

const confirmRemoveUserTaskbarTab = async () => {
  if (!props.taskbarTab.taskbarTabId) return

  if (props.plugin?.confirmTabRemove) {
    // Redirect to taskbar tab that is to be closed, if:
    //   * it has a dirty state
    //   * it's not the currently active tab
    //   * the tab link can be computed
    if (
      props.dirty &&
      props.taskbarTab.tabEntityKey !== activeTaskbarTabEntityKey.value &&
      typeof props.plugin?.buildTaskbarTabLink === 'function'
    ) {
      const link = props.plugin.buildTaskbarTabLink(
        props.taskbarTab.entity,
        props.taskbarTab.tabEntityKey,
      )
      if (link) await router.push(link)
    }

    if (props.dirty) {
      const { waitForVariantConfirmation } = useConfirmation()
      const confirmed = await waitForVariantConfirmation(
        'unsaved',
        undefined,
        `ticket-unsaved-${props.taskbarTab.tabEntityKey}`,
      )

      if (!confirmed) return
    }
  }

  // Redirection to a historical route will be handled by the store.
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
