<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed, useId } from 'vue'
import { useRouter } from 'vue-router'

import { i18n } from '#shared/i18n.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import {
  navigationIconButtonClass,
  navigationItemClass,
  navigationItemHighlightClass,
} from '#desktop/components/PageNavigation/navigationItemClasses.ts'
import type { NavigationItemComponentProps } from '#desktop/components/PageNavigation/types.ts'
import { useChatAccess } from '#desktop/entities/chat/composables/useChatAccess.ts'
import { useChatAgentStore } from '#desktop/entities/chat/stores/chatAgent.ts'
import { useChatUnreadMessagesStore } from '#desktop/entities/chat/stores/chatUnreadMessages.ts'

import ChatAvailabilitySwitch from './ChatAvailabilitySwitch.vue'

const props = defineProps<NavigationItemComponentProps>()

const router = useRouter()

// Like the old interface: no entry while the chat feature is off, while the page
//   itself stays reachable and explains what is missing.
const { isChatEnabled } = useChatAccess()

const { waitingCount } = storeToRefs(useChatAgentStore())

const { total: unreadCount } = storeToRefs(useChatUnreadMessagesStore())

// Like the old interface, one number for the waiting customers and the unread messages.
const count = computed(() => waitingCount.value + unreadCount.value)

const hasCount = computed(() => count.value > 0)

const truncatedCount = computed(() => (count.value > 99 ? '99+' : count.value))

const waitingCustomersLabel = computed(() => {
  if (!waitingCount.value) return ''

  return waitingCount.value === 1
    ? i18n.t('%s waiting customer', '1')
    : i18n.t('%s waiting customers', String(waitingCount.value))
})

const unreadMessagesLabel = computed(() => {
  if (!unreadCount.value) return ''

  return unreadCount.value === 1
    ? i18n.t('%s unread message', '1')
    : i18n.t('%s unread messages', String(unreadCount.value))
})

// What the number stands for, read as part of the link and button names.
const countLabel = computed(() =>
  [waitingCustomersLabel.value, unreadMessagesLabel.value].filter(Boolean).join(', '),
)

const openChat = () => router.push(props.route.path)

const titleId = useId()
const countId = useId()

// The count is part of the entry's name only while there is one to read.
const linkLabelledBy = computed(() => (hasCount.value ? `${titleId} ${countId}` : undefined))

const buttonDescribedBy = computed(() => (hasCount.value ? countId : undefined))
</script>

<template>
  <div v-if="isChatEnabled" class="relative flex grow" :class="{ 'justify-center': collapsed }">
    <template v-if="collapsed">
      <CommonButton
        v-tooltip="$t('Customer Chat')"
        :class="navigationIconButtonClass"
        size="large"
        variant="neutral"
        :icon="route.meta.icon"
        :aria-describedby="buttonDescribedBy"
        @click="openChat"
      />
      <CommonBadge
        v-if="hasCount"
        :id="countId"
        class="pointer-events-none absolute top-1 ltr:right-1 rtl:left-1"
        size="dot"
        variant="highlight"
      >
        <span class="sr-only">{{ countLabel }}</span>
      </CommonBadge>
    </template>
    <!--
      The switch is a sibling of the link, laid over its end: interactive content
      must not nest inside an anchor, and this way toggling never navigates.
    -->
    <template v-else>
      <CommonLink
        class="hover:no-underline! focus-visible:rounded-lg! ltr:pr-12 rtl:pl-12"
        :class="[navigationItemClass, { [navigationItemHighlightClass]: active }]"
        :aria-labelledby="linkLabelledBy"
        :link="route.path"
        exact-active-class="w-full"
        internal
      >
        <CommonLabel
          :id="titleId"
          class="gap-2 text-sm! text-current!"
          size="medium"
          :prefix-icon="route.meta.icon"
        >
          {{ $t('Customer Chat') }}
        </CommonLabel>
        <CommonBadge
          v-if="hasCount"
          class="min-w-4.5 leading-3.5 font-bold ltr:ml-auto rtl:mr-auto"
          :class="{ 'bg-white! text-blue-800!': active }"
          size="xs"
          variant="highlight"
          rounded
        >
          <span aria-hidden="true">{{ truncatedCount }}</span>
          <span :id="countId" class="sr-only">{{ countLabel }}</span>
        </CommonBadge>
      </CommonLink>
      <ChatAvailabilitySwitch />
    </template>
  </div>
</template>
