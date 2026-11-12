<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed } from 'vue'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonEmptyMessage from '#desktop/components/CommonEmptyMessage/CommonEmptyMessage.vue'
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'
import { useChatAccess } from '#desktop/entities/chat/composables/useChatAccess.ts'
import { useChatAgentStore } from '#desktop/entities/chat/stores/chatAgent.ts'
import { useChatWindowsStore } from '#desktop/entities/chat/stores/chatWindows.ts'

import ChatCustomersWaiting from '../components/ChatCustomersWaiting.vue'
import ChatNotEnabled from '../components/ChatNotEnabled.vue'
import ChatNoTopics from '../components/ChatNoTopics.vue'
import ChatToolbar from '../components/ChatToolbar.vue'
import ChatWorkspace from '../components/ChatWorkspace.vue'
import { useChatSettingsFlyout } from '../composables/useChatSettingsFlyout.ts'

const breadcrumbItems = [{ label: __('Chat') }]

const { isChatEnabled } = useChatAccess()

const { isLoaded, waitingCount, hasSelectedTopic, topics } = storeToRefs(useChatAgentStore())

const chatWindows = useChatWindowsStore()

const { sessionIds, windowToReveal } = storeToRefs(chatWindows)

const { openChatSettingsFlyout } = useChatSettingsFlyout()

// Like the availability switch: a single topic the server takes when the agent switches on.
const needsTopicChoice = computed(() => !hasSelectedTopic.value && topics.value.length !== 1)

// Without a topic nobody waits for the agent, so the page points to the settings instead;
//   a conversation still open from before keeps its window. Not before the first result:
//   an empty window list stands for "not loaded" until then.
const hasNoTopics = computed(
  () => isLoaded.value && needsTopicChoice.value && sessionIds.value.length === 0,
)

const isEmpty = computed(
  () =>
    isLoaded.value &&
    !needsTopicChoice.value &&
    waitingCount.value === 0 &&
    sessionIds.value.length === 0,
)

const hasOnlyWaitingCustomers = computed(
  () =>
    isLoaded.value &&
    !needsTopicChoice.value &&
    waitingCount.value > 0 &&
    sessionIds.value.length === 0,
)
</script>

<template>
  <LayoutContent class="relative" :breadcrumb-items="breadcrumbItems" no-scrollable content-padding>
    <template v-if="isChatEnabled && isLoaded && !hasNoTopics" #headerRight>
      <CommonButton
        variant="tertiary"
        size="small"
        prefix-icon="gear"
        @click="openChatSettingsFlyout"
      >
        {{ $t('Settings') }}
      </CommonButton>
    </template>

    <ChatNotEnabled v-if="!isChatEnabled" />

    <!-- The windows of the agent's conversations; without any, the drawn empty page. -->
    <div v-else class="h-full min-h-0 px-4">
      <!-- Centred in the row of the breadcrumb, which stays free for the settings button. -->
      <div
        v-if="isLoaded"
        class="pointer-events-none absolute inset-x-0 top-4 z-10 flex justify-center"
      >
        <ChatToolbar class="pointer-events-auto" />
      </div>

      <!-- The empty states lie over the windows' area, which takes the whole height, and stay below
        the breadcrumb: on a short screen they would otherwise cover the settings button. -->
      <div class="relative h-full">
        <!-- Always there, so the last window still scales out when it closes. -->
        <ChatWorkspace
          v-model:window-to-reveal="windowToReveal"
          class="h-full pt-2 pb-4"
          :session-ids="sessionIds"
          @close="chatWindows.closeWindow"
        />

        <div v-if="isEmpty" class="absolute inset-0 overflow-hidden">
          <CommonEmptyMessage
            class="absolute top-1/2 w-full -translate-y-1/2 text-center ltr:left-1/2 ltr:-translate-x-1/2 rtl:right-1/2 rtl:translate-x-1/2"
            :title="$t('No waiting customers')"
            :text="$t('All chats have been answered.')"
            with-illustration
          />
        </div>

        <div v-else-if="hasOnlyWaitingCustomers" class="absolute inset-0 overflow-hidden">
          <ChatCustomersWaiting />
        </div>
      </div>

      <!-- After the windows' area, which would lie over it and take its clicks. -->
      <ChatNoTopics v-if="hasNoTopics" @open-settings="openChatSettingsFlyout" />
    </div>
  </LayoutContent>
</template>
