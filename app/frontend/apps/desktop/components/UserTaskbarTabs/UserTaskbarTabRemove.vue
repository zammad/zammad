<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { useTouchDevice } from '#shared/composables/useTouchDevice.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

import { useTaskbarTabRemove } from './useTaskbarTabRemove.ts'

import type { UserTaskbarTab, UserTaskbarTabPlugin } from './types.ts'

interface Props {
  taskbarTab: UserTaskbarTab
  dirty?: boolean
  plugin?: UserTaskbarTabPlugin
}

const props = defineProps<Props>()

const { isTouchDevice } = useTouchDevice()

const { removeTaskbarTab } = useTaskbarTabRemove()

// Red only where the click closes the tab right away: a dirty tab of a plugin that asks first
//   is asked about first, so its button is not the point of no return.
const variant = computed(() =>
  props.plugin?.confirmTabRemove && props.dirty ? 'tertiary' : 'remove',
)

const confirmRemoveUserTaskbarTab = () =>
  removeTaskbarTab(props.taskbarTab, props.dirty, props.plugin)
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
