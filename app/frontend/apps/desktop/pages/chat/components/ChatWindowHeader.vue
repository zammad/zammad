<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, useTemplateRef } from 'vue'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'

import CommonActionMenu from '#desktop/components/CommonActionMenu/CommonActionMenu.vue'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonInlineEdit from '#desktop/components/CommonInlineEdit/CommonInlineEdit.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import type { ChatEnding } from '#desktop/entities/chat/types.ts'

interface Props {
  name: string
  title: string
  isRenamable: boolean
  isClosed: boolean
  isWaiting?: boolean
  canEnd?: boolean
  canClose?: boolean
  ending?: ChatEnding
  isEnding?: boolean
  actions: MenuItem[]
  // Resolves once the server stored the change.
  rename: (name: string) => Promise<unknown>
}

const props = defineProps<Props>()

const { notify } = useNotifications()

// Resolves without a value: the inline edit calls a function it resolves with.
const submitName = async (name: string) => {
  if (name === props.name) return

  await props.rename(name)

  notify({
    type: NotificationTypes.Success,
    id: 'chat-session-renamed',
    message: __('Chat renamed successfully.'),
  })
}

defineEmits<{
  end: []
  close: []
}>()

const actionMenu = useTemplateRef('action-menu')

// Without scrolling, like the window itself: the row of windows would move.
const focusActions = () =>
  actionMenu.value?.$el?.querySelector?.('[aria-haspopup]')?.focus({ preventScroll: true })

defineExpose({ focusActions })

// The customer who left is gone for good, unlike one who closed the conversation themself.
const state = computed(() => {
  if (props.ending?.reason === 'left')
    return {
      label: __('Disconnected'),
      variant: 'danger',
      icon: 'exclamation-triangle',
    } as const
  if (props.isClosed)
    return {
      label: __('Closed'),
      variant: 'tertiary',
      icon: 'check2-all',
    } as const
  if (props.isWaiting)
    return {
      label: __('Waiting'),
      variant: 'info',
      icon: 'clock',
    } as const

  return {
    label: __('Online'),
    variant: 'success',
    icon: 'person-workspace',
  } as const
})
</script>

<template>
  <!-- A container, as four windows to a row leave the header too little room for the button's label
    on a small screen; the button keeps its icon then, at the height its label gives it. -->
  <header class="@container grid grid-cols-[auto_minmax(0,1fr)_auto] items-center gap-3 px-3 py-2">
    <CommonBadge
      v-tooltip="$t(state.label)"
      class="justify-self-start"
      :variant="state.variant"
      size="circle"
      role="img"
    >
      <CommonIcon :name="state.icon" size="xs" decorative />
    </CommonBadge>

    <CommonInlineEdit
      size="medium"
      required
      block
      single-line
      max-length="250"
      :value="title"
      :initial-edit-value="name"
      :disabled="!isRenamable"
      :classes="{ label: 'line-clamp-1! w-full' }"
      :label-attrs="{
        role: 'heading',
        'aria-level': '2',
      }"
      :label="$t('Edit chat name')"
      @submit-edit="submitName"
    />

    <div class="flex items-center gap-2 justify-self-end">
      <CommonButton
        v-if="canEnd"
        v-tooltip="$t('Disconnect')"
        variant="tertiary"
        size="small"
        :disabled="isEnding"
        @click="$emit('end')"
      >
        <template #label>
          <span class="flex h-4 items-center">
            <CommonIcon class="pointer-events-none" name="x-square" size="xs" decorative />
          </span>

          <span class="sr-only whitespace-nowrap @3xs:not-sr-only">{{ $t('Disconnect') }}</span>
        </template>
      </CommonButton>

      <!-- The name says what closes: the old UI's bare "close" read as ending the conversation. -->
      <CommonButton
        v-else-if="canClose"
        v-tooltip="$t('Close window')"
        variant="tertiary"
        size="small"
        @click="$emit('close')"
      >
        <template #label>
          <span class="flex h-4 items-center">
            <CommonIcon class="pointer-events-none" name="x-lg" size="xs" decorative />
          </span>

          <span class="sr-only whitespace-nowrap @3xs:not-sr-only">{{ $t('Close') }}</span>
        </template>
      </CommonButton>

      <CommonActionMenu
        ref="action-menu"
        :actions="actions"
        :custom-menu-button-label="$t('Additional actions')"
        button-size="medium"
        no-single-action-mode
      />
    </div>
  </header>
</template>
