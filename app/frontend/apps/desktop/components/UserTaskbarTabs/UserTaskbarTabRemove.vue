<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'
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
const { deleteTaskbarTab } = taskbarTabStore
const activeTaskbarTabEntityKey = toRef(taskbarTabStore, 'activeTaskbarTabEntityKey')

const { isTouchDevice } = useTouchDevice()

const router = useRouter()

// Red only where the click closes the tab right away: a dirty tab of a plugin that asks first
//   gets the question below, so its button is not the point of no return.
const variant = computed(() =>
  props.plugin?.confirmTabRemove && props.dirty ? 'tertiary' : 'remove',
)

const confirmRemoveUserTaskbarTab = async () => {
  if (!props.taskbarTab.taskbarTabId) return

  if (props.plugin?.confirmTabRemove) {
    // Redirect to the taskbar tab that is to be closed, if:
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

  // The store will handle redirection to a historical route.
  deleteTaskbarTab(props.taskbarTab.taskbarTabId)
}
</script>

<template>
  <CommonButton
    v-tooltip="$t('Close this tab')"
    :class="{ 'opacity-0 transition-opacity': !isTouchDevice }"
    class="absolute inset-e-2 top-3 group-hover/tab:opacity-100 focus:opacity-100"
    icon="x-lg"
    size="small"
    :variant="variant"
    @click.stop="confirmRemoveUserTaskbarTab"
  />
</template>

<style scoped>
.dragging-active button {
  visibility: hidden;
}
</style>
