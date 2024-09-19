<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import { useMacros } from '#shared/entities/macro/composables/useMacros.ts'
import type { MacroById } from '#shared/entities/macro/types.ts'
import type { TicketLiveAppUser } from '#shared/entities/ticket/types.ts'

import CommonActionMenu from '#desktop/components/CommonActionMenu/CommonActionMenu.vue'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import TicketScreenBehavior from '#desktop/pages/ticket/components/TicketDetailView/TicketScreenBehavior/TicketScreenBehavior.vue'

import TicketLiveUsers from './TicketLiveUsers.vue'

export interface Props {
  dirty: boolean
  disabled: boolean
  formNodeId?: string
  isTicketEditable: boolean
  groupId?: string
  liveUserList: TicketLiveAppUser[]
}

const props = defineProps<Props>()

const groupId = toRef(props, 'groupId')

const emit = defineEmits<{
  submit: [MouseEvent]
  discard: [MouseEvent]
  'execute-macro': [MacroById]
}>()

const { macros } = useMacros(groupId)

const groupLabels = {
  drafts: __('Drafts'),
  macros: __('Macros'),
}

const actionItems = computed(() => {
  if (!macros.value) return null

  const macroMenu = macros.value.map((macro) => ({
    key: macro.id,
    label: macro.name,
    groupLabel: groupLabels.macros,
    onClick: () => emit('execute-macro', macro),
  }))

  return [
    // :TODO add later drafts action item
    // {
    //   label: __('Save as draft'),
    //   groupLabel: groupLabels.drafts,
    //   icon: 'floppy',
    //   key: 'macro1',
    //   onClick: () => {},
    // },
    ...(groupId.value ? macroMenu : []),
  ]
})
</script>

<template>
  <TicketLiveUsers v-if="liveUserList?.length" :live-user-list="liveUserList" />
  <template v-if="isTicketEditable">
    <CommonButton
      v-if="dirty"
      size="large"
      variant="danger"
      :disabled="disabled"
      @click="$emit('discard', $event)"
      >{{ $t('Discard your unsaved changes') }}</CommonButton
    >

    <TicketScreenBehavior />

    <CommonButton
      size="large"
      variant="submit"
      type="button"
      :form="formNodeId"
      :disabled="disabled"
      @click="$emit('submit', $event)"
      >{{ $t('Update') }}</CommonButton
    >
    <CommonActionMenu
      v-if="actionItems"
      class="flex"
      button-size="large"
      no-single-action-mode
      placement="arrowEnd"
      :actions="actionItems"
    />
  </template>
</template>
