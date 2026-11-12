<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { useSessionStore } from '#shared/stores/session.ts'

import CommonEmptyMessage from '#desktop/components/CommonEmptyMessage/CommonEmptyMessage.vue'

const session = useSessionStore()

// The chat channel's admin page in the old UI is where the feature is switched on.
const canConfigure = computed(() => session.hasPermission('admin.channel_chat'))
</script>

<template>
  <CommonEmptyMessage
    class="absolute top-1/2 w-full -translate-y-1/2 text-center ltr:left-1/2 ltr:-translate-x-1/2 rtl:right-1/2 rtl:translate-x-1/2"
    :title="$t('Sorry, the chat feature is currently disabled.')"
    icon="x-circle"
  >
    <CommonLink
      v-if="canConfigure"
      class="block pt-5"
      link="/#channels/chat"
      external
      size="medium"
    >
      {{ $t('Enable it in the chat channel settings.') }}
    </CommonLink>
  </CommonEmptyMessage>
</template>
