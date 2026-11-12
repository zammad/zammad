<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed } from 'vue'

import { useChatAgentStore } from '#desktop/entities/chat/stores/chatAgent.ts'

const chatAgent = useChatAgentStore()

const { isAvailable, hasSelectedTopic, topics } = storeToRefs(chatAgent)

const modelAvailable = computed({
  get: () => isAvailable.value,
  set: (active) => {
    chatAgent.setAvailable(active)
  },
})

// Without a topic there is nothing to switch on, unless there is a single one, which the server takes;
//   an agent still available keeps the switch to go off.
const isDisabled = computed(
  () => !hasSelectedTopic.value && topics.value.length !== 1 && !isAvailable.value,
)

// Laid over the end of the navigation link, whose sibling it is.
const outerClass = computed(
  () =>
    `absolute top-1/2 -translate-y-1/2 ltr:right-2 rtl:left-2${isDisabled.value ? ' opacity-50' : ''}`,
)

const hint = __(
  'You need to subscribe to at least one topic in the settings to enable chat availability.',
)
</script>

<template>
  <!--
    Marked disabled rather than disabled, like the items of the popover menu: it keeps hover and focus
    for the reason, and setAvailable lets a click snap back.
  -->
  <FormKit
    v-model="modelAvailable"
    v-tooltip.supportive="isDisabled ? $t(hint) : undefined"
    type="toggle"
    size="small"
    :outer-class="outerClass"
    :label="__('Chat availability')"
    :label-sr-only="true"
    :variants="{ true: 'True', false: 'False' }"
    :aria-disabled="isDisabled"
    :aria-description="isDisabled ? $t(hint) : undefined"
    wrapper-class="!px-0 $remove:h-10"
  />
</template>
