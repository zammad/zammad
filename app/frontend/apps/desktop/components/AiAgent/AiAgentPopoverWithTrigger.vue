<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonPopoverWithTrigger, {
  type Props as CommonPopoverWithTriggerProps,
} from '#desktop/components/CommonPopover/CommonPopoverWithTrigger.vue'

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
        <CommonLabel class="text-base! dark:text-white! text-black! block!" tag="h3">
          {{ $t('AI Agent') }}
        </CommonLabel>

        <CommonLabel tag="p">
          {{ $t('Currently processing this ticket…') }}
        </CommonLabel>
      </div>
    </template>

    <div
      class="relative size-8 rounded-full before:bg-gradient-to-r before:from-blue-800 before:to-pink-200 before:absolute before:w-full before:inset-0 before:size-full before:-z-1 before:rounded-full before:animate-spin before:[animation-duration:2s]"
    >
      <div
        :aria-label="$t('AI Agent')"
        class="p-1 bg-neutral-50 dark:bg-gray-500 rounded-[inherit] border border-transparent bg-clip-padding h-full flex"
      >
        <CommonIcon class="text-blue-800" size="base" name="ai-agent" />
      </div>

      <span
        class="absolute end-0 bottom-0 flex translate-y-1 items-center justify-center rounded-full bg-blue-200 p-[3px] outline-1 -outline-offset-1 outline-neutral-100 ltr:translate-x-2 rtl:-translate-x-2 dark:bg-gray-700 dark:outline-gray-900"
      >
        <CommonIcon
          :aria-label="$t('User is editing')"
          class="text-black dark:text-white"
          size="xs"
          name="avatar-indicator-editing-desktop"
        />
      </span>
    </div>
  </CommonPopoverWithTrigger>
</template>
