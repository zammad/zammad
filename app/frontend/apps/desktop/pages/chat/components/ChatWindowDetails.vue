<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref } from 'vue'

import CommonDateTime from '#shared/components/CommonDateTime/CommonDateTime.vue'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import type { ChatTopic } from '#desktop/entities/chat/types.ts'
import type { ChatConversationSession } from '#desktop/entities/chat/types.ts'

import ChatWindowTags from './ChatWindowTags.vue'

import type { ChatWindowDetail } from './types.ts'

interface Props {
  session: Pick<
    ChatConversationSession,
    'id' | 'internalId' | 'tags' | 'topic' | 'createdAt' | 'geoIp' | 'remoteIp' | 'dnsName'
  >
  topics: ChatTopic[]
  view: ChatWindowDetail
  isClosed: boolean
  // Resolves once the server stored the change.
  transfer: (topicId: string) => Promise<unknown>
}

const props = defineProps<Props>()

const emit = defineEmits<{
  done: []
  transferred: []
}>()

const topicOptions = computed(() =>
  props.topics
    .filter((topic) => topic.id !== props.session.topic.id)
    .map((topic) => ({ value: topic.id, label: topic.name })),
)

const selectedTopicId = ref<string>()

const onTopicInput = (value: unknown) => {
  selectedTopicId.value = typeof value === 'string' ? value : undefined
}

const isTransferring = ref(false)

const transferToTopic = async () => {
  if (!selectedTopicId.value) return

  isTransferring.value = true

  try {
    await props.transfer(selectedTopicId.value)

    emit('transferred')
  } catch {
    // The handler already told the agent.
  } finally {
    isTransferring.value = false
  }
}

const geoLocation = computed(() =>
  [props.session.geoIp?.countryName, props.session.geoIp?.cityName].filter(Boolean).join(', '),
)
</script>

<template>
  <div
    class="absolute inset-x-0 top-0 z-10 flex max-h-full flex-col gap-6 overflow-y-auto border-y border-neutral-100 bg-neutral-50 px-3 py-6 dark:border-gray-900 dark:bg-gray-500"
  >
    <template v-if="view === 'transfer'">
      <FormKit
        type="select"
        :label="__('Transfer to another topic')"
        :options="topicOptions"
        :clearable="true"
        :disabled="isClosed || isTransferring || !topicOptions.length"
        @input="onTopicInput"
      />

      <div class="flex justify-end gap-2">
        <CommonButton
          variant="secondary"
          size="medium"
          :disabled="isTransferring"
          @click="$emit('done')"
        >
          {{ $t('Cancel') }}
        </CommonButton>

        <CommonButton
          variant="submit"
          size="medium"
          :disabled="!selectedTopicId || isClosed || isTransferring"
          @click="transferToTopic"
        >
          {{ $t('Transfer chat') }}
        </CommonButton>
      </div>
    </template>

    <template v-else-if="view === 'tags'">
      <ChatWindowTags :session="session" />

      <CommonButton class="self-end" variant="secondary" size="medium" @click="$emit('done')">
        {{ $t('OK') }}
      </CommonButton>
    </template>

    <template v-else>
      <dl class="grid grid-cols-[auto_1fr] gap-x-3 gap-y-1">
        <dt>
          <CommonLabel size="small">{{ $t('Created at') }}</CommonLabel>
        </dt>
        <dd>
          <CommonLabel size="small">
            <CommonDateTime :date-time="session.createdAt" type="absolute" />
          </CommonLabel>
        </dd>

        <template v-if="geoLocation">
          <dt>
            <CommonLabel size="small">{{ $t('GeoIP') }}</CommonLabel>
          </dt>
          <dd>
            <CommonLabel size="small" class="gap-1" icon-color="text-muted" suffix-icon="globe">
              {{ geoLocation }}
            </CommonLabel>
          </dd>
        </template>

        <template v-if="session.remoteIp">
          <dt>
            <CommonLabel size="small">{{ $t('IP address') }}</CommonLabel>
          </dt>
          <dd>
            <CommonLabel size="small" class="break-all">{{ session.remoteIp }}</CommonLabel>
          </dd>
        </template>

        <template v-if="session.dnsName">
          <dt>
            <CommonLabel size="small">{{ $t('DNS name') }}</CommonLabel>
          </dt>
          <dd>
            <CommonLabel size="small" class="break-all">{{ session.dnsName }}</CommonLabel>
          </dd>
        </template>
      </dl>

      <CommonButton class="self-end" variant="secondary" size="medium" @click="$emit('done')">
        {{ $t('OK') }}
      </CommonButton>
    </template>
  </div>
</template>
