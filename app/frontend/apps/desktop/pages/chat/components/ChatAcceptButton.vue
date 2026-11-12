<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import { useChatSessionAccept } from '#desktop/entities/chat/composables/useChatSessionAccept.ts'
import type { ChatTopic } from '#desktop/entities/chat/types.ts'

interface Props {
  topic: ChatTopic
}

const props = defineProps<Props>()

const { accept, isAccepting, isLimitReached } = useChatSessionAccept()
</script>

<template>
  <CommonButton
    variant="tertiary"
    size="small"
    :disabled="isLimitReached || isAccepting"
    @click="accept(props.topic.id)"
  >
    {{ $t('Accept next') }}
  </CommonButton>
</template>
