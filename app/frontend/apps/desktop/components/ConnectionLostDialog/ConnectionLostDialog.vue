<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonDialog from '#desktop/components/CommonDialog/CommonDialog.vue'
</script>

<template>
  <CommonDialog
    name="connection-lost"
    :header-title="__('Lost network connection')"
    wrapper-tag="article"
    hide-footer
    no-close
    global
    fullscreen
  >
    <div class="flex justify-center">
      <CommonIcon
        name="wifi-off"
        size="medium"
        class="text-stone-200 dark:text-neutral-500"
        animation="pulse"
      />
    </div>
    <CommonLabel size="large">{{ $t('Trying to reconnect…') }}</CommonLabel>
  </CommonDialog>
</template>
