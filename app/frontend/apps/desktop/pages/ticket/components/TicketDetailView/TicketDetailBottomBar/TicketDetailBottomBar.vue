<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import type { FormRef } from '#shared/components/Form/types.ts'
import { useMacros } from '#shared/entities/macro/composables/useMacros.ts'
import type { MacroById } from '#shared/entities/macro/types.ts'
import type { TicketLiveAppUser } from '#shared/entities/ticket/types.ts'
import { useTicketSharedDraftZoomCreateMutation } from '#shared/entities/ticket-shared-draft-zoom/graphql/mutations/ticketSharedDraftZoomCreate.api.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'

import CommonActionMenu from '#desktop/components/CommonActionMenu/CommonActionMenu.vue'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import { useDialog } from '#desktop/components/CommonDialog/useDialog.ts'
import TicketScreenBehavior from '#desktop/pages/ticket/components/TicketDetailView/TicketScreenBehavior/TicketScreenBehavior.vue'
import { useTicketSharedDraft } from '#desktop/pages/ticket/composables/useTicketSharedDraft.ts'

import TicketLiveUsers from './TicketLiveUsers.vue'
import TicketSharedDraftZoom from './TicketSharedDraftZoom.vue'

export interface Props {
  dirty: boolean
  disabled: boolean
  isTicketEditable: boolean
  isTicketAgent: boolean
  ticketId: string
  groupId?: string
  form?: FormRef
  hasAvailableDraft?: boolean
  canUseDraft?: boolean
  sharedDraftId?: string | null
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

const { notify } = useNotifications()

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
    {
      label: __('Save as draft'),
      groupLabel: groupLabels.drafts,
      icon: 'floppy',
      key: 'save-draft',
      show: () => props.canUseDraft,
      onClick: () => {
        const { mapSharedDraftParams } = useTicketSharedDraft()

        if (props.sharedDraftId) {
          const sharedDraftConflictDialog = useDialog({
            name: 'shared-draft-conflict',
            component: () => import('../TicketSharedDraftConflictDialog.vue'),
          })

          sharedDraftConflictDialog.open({
            sharedDraftId: props.sharedDraftId,
            sharedDraftParams: mapSharedDraftParams(props.ticketId, props.form),
            form: props.form,
          })

          return
        }

        const draftCreateMutation = new MutationHandler(
          useTicketSharedDraftZoomCreateMutation(),
          {
            errorNotificationMessage: __('Draft could not be saved.'),
          },
        )

        draftCreateMutation
          .send({ input: mapSharedDraftParams(props.ticketId, props.form) })
          .then(() => {
            notify({
              id: 'shared-draft-detail-view-created',
              type: NotificationTypes.Success,
              message: __('Shared draft has been created successfully.'),
            })
          })
      },
    },
    ...(groupId.value ? macroMenu : []),
  ]
})
</script>

<template>
  <div class="flex gap-4 ltr:mr-auto rtl:ml-auto">
    <TicketLiveUsers
      v-if="liveUserList?.length"
      :live-user-list="liveUserList"
    />

    <TicketSharedDraftZoom
      v-if="hasAvailableDraft"
      :form="form"
      :shared-draft-id="sharedDraftId"
    />
  </div>

  <template v-if="isTicketEditable">
    <CommonButton
      v-if="dirty"
      size="large"
      variant="danger"
      :disabled="disabled"
      @click="$emit('discard', $event)"
      >{{ $t('Discard your unsaved changes') }}
    </CommonButton>

    <TicketScreenBehavior />

    <CommonButton
      size="large"
      variant="submit"
      type="button"
      :disabled="disabled"
      @click="$emit('submit', $event)"
      >{{ $t('Update') }}
    </CommonButton>
    <CommonActionMenu
      v-if="isTicketAgent && actionItems"
      class="flex"
      button-size="large"
      no-single-action-mode
      placement="arrowEnd"
      custom-menu-button-label="Additional ticket edit actions"
      :actions="actionItems"
    />
  </template>
</template>
