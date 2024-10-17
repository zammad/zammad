<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { nextTick, toRef, watch } from 'vue'

import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import { useTicketSubscribe } from '#shared/entities/ticket/composables/useTicketSubscribe.ts'
import type { TicketById } from '#shared/entities/ticket/types.ts'

export interface Props {
  ticket?: TicketById
}

const props = defineProps<Props>()

const ticketReactive = toRef(props, 'ticket')

const {
  isSubscribed,
  isSubscriptionLoading,
  toggleSubscribe,
  subscribers,
  totalSubscribers,
} = useTicketSubscribe(ticketReactive)

let isOutsideUpdate = false
watch(
  () => isSubscribed.value,
  () => {
    isOutsideUpdate = true
    nextTick(() => {
      isOutsideUpdate = false
    })
  },
)

const handleToggleInput = async () => {
  // do not trigger update, if value was changed from the outside,
  // and not by clicking on toggle button, otherwise it goes into infinite loop
  if (isOutsideUpdate) return false
  return toggleSubscribe()
}
</script>

<template>
  <div class="flex flex-col gap-2">
    <div
      class="flex w-full flex-col rounded-lg bg-blue-200 p-2.5 dark:bg-gray-700"
    >
      <div
        class="flex gap-2"
        :class="{
          'border-b border-white/10 pb-2': subscribers.length,
        }"
      >
        <FormKit
          type="toggle"
          :model-value="isSubscribed"
          :label="__('Subscribe')"
          :variants="{
            true: __('yes'),
            false: __('no'),
          }"
          :disabled="isSubscriptionLoading"
          outer-class="grow"
          wrapper-class="!px-0"
          @input-raw="handleToggleInput"
        />
      </div>
      <div v-if="totalSubscribers > 0" class="flex flex-wrap gap-1.5 pt-2.5">
        <CommonUserAvatar
          v-for="subscriber in subscribers"
          :key="subscriber.id"
          :entity="subscriber"
          size="small"
        />
      </div>
    </div>
  </div>
</template>
