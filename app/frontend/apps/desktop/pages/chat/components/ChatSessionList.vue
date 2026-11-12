<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed, useId } from 'vue'

import { useChatPreferencesStore } from '#desktop/entities/chat/stores/chatPreferences.ts'
import type { ChatSession, ChatTopic } from '#desktop/entities/chat/types.ts'

import ChatSessionRow from './ChatSessionRow.vue'
import ChatWaitingTopicHeader from './ChatWaitingTopicHeader.vue'

interface Props {
  sessions: ChatSession[]
  emptyText: string
  showAgent?: boolean
  // For the waiting customers of an agent who handles several topics: a group per topic, each with
  //   a button to take its longest waiting customer.
  groupByTopic?: boolean
}

const props = defineProps<Props>()

// Without grouping, all sessions form a single group without a heading.
const groups = computed(() => {
  if (!props.groupByTopic) return [{ topic: null, sessions: props.sessions }]

  const topics = new Map<string, { topic: ChatTopic; sessions: ChatSession[] }>()

  props.sessions.forEach((session) => {
    const group = topics.get(session.topic.id) ?? { topic: session.topic, sessions: [] }

    group.sessions.push(session)
    topics.set(session.topic.id, group)
  })

  return [...topics.values()]
})

const { isLimitReached } = storeToRefs(useChatPreferencesStore())

// A disabled button takes no focus and no hover: the reason stands above the groups, once for all of
//   their buttons, as their description.
const showLimitReason = computed(() => props.groupByTopic && isLimitReached.value)

const limitReasonId = useId()

const describedBy = computed(() => (showLimitReason.value ? limitReasonId : undefined))

const gridColumns = computed(() =>
  props.showAgent ? 'grid-cols-[auto_auto_auto]' : 'grid-cols-[auto_auto]',
)
</script>

<template>
  <CommonLabel v-if="!sessions.length" class="px-3 py-2" size="small">{{ emptyText }}</CommonLabel>

  <!-- One grid for all groups, so their columns line up. -->
  <div v-else class="grid gap-y-2" :class="gridColumns">
    <CommonLabel
      v-if="showLimitReason"
      :id="limitReasonId"
      class="col-span-full text-stone-200 dark:text-neutral-400"
      size="xs"
    >
      {{ $t('You have reached the maximum number of concurrent chats.') }}
    </CommonLabel>

    <template v-for="group in groups" :key="group.topic?.id ?? 'all'">
      <ChatWaitingTopicHeader
        v-if="group.topic"
        class="col-span-full not-first:mt-2"
        :topic="group.topic"
        :count="group.sessions.length"
        :limit-reason-id="describedBy"
      />

      <ul class="col-span-full grid grid-cols-subgrid">
        <ChatSessionRow
          v-for="session in group.sessions"
          :key="session.id"
          :session="session"
          :show-agent="showAgent"
        />
      </ul>
    </template>
  </div>
</template>
