<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { useRouter } from 'vue-router'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import { useChatPreferencesStore } from '#desktop/entities/chat/stores/chatPreferences.ts'
import { chatTicketCreateRoute } from '#desktop/entities/chat/utils.ts'

interface Props {
  sessionId: string
}

const props = defineProps<Props>()

const { hasTicketCreateAccess } = storeToRefs(useChatPreferencesStore())

const deniedReason = __('You have no permission to create tickets in any group.')

const router = useRouter()

const createTicket = () => {
  if (!hasTicketCreateAccess.value) return

  router.push(chatTicketCreateRoute(props.sessionId))
}
</script>

<template>
  <!--
    Marked disabled rather than disabled, like the items of the popover menu: it keeps hover and focus
    for the reason, and a click does nothing.
  -->
  <CommonButton
    v-tooltip.supportive="hasTicketCreateAccess ? undefined : $t(deniedReason)"
    variant="primary"
    size="medium"
    :class="{ 'opacity-30': !hasTicketCreateAccess }"
    :aria-disabled="hasTicketCreateAccess ? undefined : 'true'"
    @click="createTicket"
  >
    {{ $t('Turn chat into a ticket') }}
  </CommonButton>
</template>
