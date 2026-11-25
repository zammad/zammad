<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { watch } from 'vue'

import { connected } from '#shared/server/connection.ts'

import CommonDialog from '#desktop/components/CommonDialog/CommonDialog.vue'
import { closeDialog } from '#desktop/components/CommonDialog/useDialog.ts'

import ConnectionLostGame from './ConnectionLostGame.vue'
import { useKonamiCode } from './useKonamiCode.ts'

const { unlocked: isGameUnlocked } = useKonamiCode()

// The connection may already be back by the time the dialog is mounted.
watch(
  connected,
  (isConnected) => {
    if (isConnected && !isGameUnlocked.value) closeDialog('connection-lost', true)
  },
  { immediate: true },
)
</script>

<template>
  <CommonDialog
    name="connection-lost"
    :header-title="connected ? __('Network connection restored') : __('Lost network connection')"
    wrapper-tag="article"
    :class="{ 'pb-0': isGameUnlocked }"
    :no-close="!connected"
    hide-footer
    global
    fullscreen
  >
    <div aria-live="polite">
      <template v-if="connected">
        <div class="flex justify-center">
          <CommonIcon name="check-circle-outline" size="medium" class="text-green-500" />
        </div>
        <CommonLabel size="large">{{
          $t('You can close this dialog and get back to work.')
        }}</CommonLabel>
      </template>
      <template v-else>
        <div class="flex justify-center">
          <CommonIcon name="wifi-off" size="medium" class="text-muted" animation="pulse" />
        </div>
        <CommonLabel size="large">{{ $t('Trying to reconnect…') }}</CommonLabel>
      </template>
    </div>
    <ConnectionLostGame v-if="isGameUnlocked" class="mt-6" />
  </CommonDialog>
</template>
