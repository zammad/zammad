<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonEmptyMessage from '#desktop/components/CommonEmptyMessage/CommonEmptyMessage.vue'
import { useChatSessionAccept } from '#desktop/entities/chat/composables/useChatSessionAccept.ts'

// Shown only without an open window, so the agent is never at the limit of concurrent chats here:
//   each of their running chats has a window, and the limit is at least one.
const { accept, isAccepting } = useChatSessionAccept()
</script>

<template>
  <CommonEmptyMessage
    class="absolute top-1/2 w-full -translate-y-1/2 text-center ltr:left-1/2 ltr:-translate-x-1/2 rtl:right-1/2 rtl:translate-x-1/2"
    :title="$t('There are waiting customers')"
    icon="chat-right-dots"
  >
    <div class="flex flex-col items-center gap-2.5 py-5">
      <div>
        <CommonLabel tag="p" class="block!">
          {{ $t('There are waiting customers in the chat queue.') }}
        </CommonLabel>
        <CommonLabel tag="p" class="block!">
          {{ $t('Are you ready to pick one of them up?') }}
        </CommonLabel>
      </div>
      <CommonButton variant="primary" size="small" :disabled="isAccepting" @click="accept()">
        {{ $t('Accept chat') }}
      </CommonButton>
    </div>
  </CommonEmptyMessage>
</template>
