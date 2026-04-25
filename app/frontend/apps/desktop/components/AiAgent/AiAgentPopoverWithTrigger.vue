<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonPopoverWithTrigger, {
  type Props as CommonPopoverWithTriggerProps,
} from '#desktop/components/CommonPopover/CommonPopoverWithTrigger.vue'

import AiAgentAvatar from './AiAgentAvatar.vue'

defineProps<CommonPopoverWithTriggerProps>()
</script>

<template>
  <CommonPopoverWithTrigger
    v-bind="$props"
    placement="arrowStart"
    class="rounded-full outline-offset-1 focus-visible:outline-2"
    trigger-link-active-class="outline-blue-800 outline-2"
  >
    <template #popover-content="{ popoverId }">
      <div :id="popoverId" class="p-3">
        <CommonLabel class="block! text-base! text-black! dark:text-white!" tag="h3">
          {{ $t('AI agent') }}
        </CommonLabel>

        <CommonLabel tag="p">
          {{ $t('Currently processing this ticket…') }}
        </CommonLabel>
      </div>
    </template>

    <AiAgentAvatar>
      <span
        class="absolute inset-e-0 bottom-0 flex translate-y-1 items-center justify-center rounded-full bg-blue-200 p-0.75 outline-1 -outline-offset-1 outline-neutral-100 ltr:translate-x-2 rtl:-translate-x-2 dark:bg-gray-700 dark:outline-gray-900"
      >
        <CommonIcon
          :aria-label="$t('User is editing')"
          class="text-black dark:text-white"
          size="xs"
          name="avatar-indicator-editing-desktop"
        />
      </span>
    </AiAgentAvatar>
  </CommonPopoverWithTrigger>
</template>
