<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed } from 'vue'

import { useChatSessionAccept } from '#desktop/entities/chat/composables/useChatSessionAccept.ts'
import { useChatAgentStore } from '#desktop/entities/chat/stores/chatAgent.ts'
import type { ChatSession } from '#desktop/entities/chat/types.ts'

import ChatAgentList from './ChatAgentList.vue'
import ChatSessionList from './ChatSessionList.vue'
import ChatToolbarCounter from './ChatToolbarCounter.vue'

const { waitingQueues, waitingCount, runningSessions, availableAgents } =
  storeToRefs(useChatAgentStore())

const { accept, isLimitReached } = useChatSessionAccept()

// Like the old interface: only while someone waits and the agent has room for another chat.
const canAccept = computed(() => waitingCount.value > 0 && !isLimitReached.value)

const limitReason = computed(() =>
  waitingCount.value > 0 && isLimitReached.value
    ? __('You have reached the maximum number of concurrent chats.')
    : undefined,
)

const oldestFirst = (a: ChatSession, b: ChatSession) =>
  new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime()

// Oldest first, so the customer "Accept next" takes leads the list.
const waitingSessions = computed(() =>
  waitingQueues.value.flatMap((queue) => queue.sessions).sort(oldestFirst),
)

// There is a queue for each topic the agent handles.
const hasSeveralTopics = computed(() => waitingQueues.value.length > 1)

const runningSessionsNewestFirst = computed(() =>
  [...runningSessions.value].sort((a, b) => oldestFirst(b, a)),
)
</script>

<template>
  <div class="flex items-center gap-1 rounded-2xl bg-blue-200 p-1 dark:bg-gray-700">
    <ChatToolbarCounter
      :label="$t('Waiting customers')"
      :trigger-label="$t('Show waiting customers')"
      :count="waitingCount"
      :accept-disabled="!canAccept"
      :accept-disabled-reason="limitReason"
      highlight
      acceptable
      @accept="accept()"
    >
      <ChatSessionList
        :sessions="waitingSessions"
        :empty-text="$t('No waiting customers')"
        :group-by-topic="hasSeveralTopics"
        show-agent
      />
    </ChatToolbarCounter>

    <ChatToolbarCounter
      :label="$t('Active chat sessions')"
      :trigger-label="$t('Show active chat sessions')"
      :count="runningSessions.length"
    >
      <ChatSessionList
        :sessions="runningSessionsNewestFirst"
        :empty-text="$t('No active chat sessions')"
        show-agent
      />
    </ChatToolbarCounter>

    <ChatToolbarCounter
      :label="$t('Active agents')"
      :trigger-label="$t('Show active agents')"
      :count="availableAgents.length"
    >
      <ChatAgentList :agents="availableAgents" />
    </ChatToolbarCounter>
  </div>
</template>
