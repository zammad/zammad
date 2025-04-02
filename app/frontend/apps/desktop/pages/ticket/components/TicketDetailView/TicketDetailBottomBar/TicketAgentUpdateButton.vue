<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import type { FormRef } from '#shared/components/Form/types.ts'
import { useMacros } from '#shared/entities/macro/composables/useMacros.ts'
import type { MacroById } from '#shared/entities/macro/types.ts'
import { useTicketSharedDraftZoomCreateMutation } from '#shared/entities/ticket-shared-draft-zoom/graphql/mutations/ticketSharedDraftZoomCreate.api.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import { useDialog } from '#desktop/components/CommonDialog/useDialog.ts'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import SplitButton from '#desktop/components/SplitButton/SplitButton.vue'

import { useTicketSharedDraft } from '../../../composables/useTicketSharedDraft.ts'

interface Props {
  ticketId: string
  form?: FormRef
  groupId?: string
  disabled: boolean
  canUseDraft?: boolean
  sharedDraftId?: string | null
}

const props = defineProps<Props>()

const emit = defineEmits<{
  submit: [MouseEvent]
  'execute-macro': [MacroById]
}>()

const groupIds = computed(() => (props.groupId ? [props.groupId] : undefined))

// For now handover ticket editable, flag, maybe later we can move the action menu in an own component.
const { macrosLoaded, macros } = useMacros(groupIds)

const { notify } = useNotifications()

const groupLabels = {
  drafts: __('Drafts'),
  macros: __('Macros'),
}

const { mapSharedDraftParams } = useTicketSharedDraft()

const sharedDraftConflictDialog = useDialog({
  name: 'shared-draft-conflict',
  component: () => import('../TicketSharedDraftConflictDialog.vue'),
})

const actionItems = computed(() => {
  const saveAsDraftAction: MenuItem = {
    label: __('Save as draft'),
    groupLabel: groupLabels.drafts,
    icon: 'floppy',
    key: 'save-draft',
    show: () => props.canUseDraft,
    onClick: () => {
      if (props.sharedDraftId) {
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
  }

  if (!macros.value) return [saveAsDraftAction]

  const macroMenu: MenuItem[] = macros.value.map((macro) => ({
    key: macro.id,
    label: macro.name,
    groupLabel: groupLabels.macros,
    icon: 'play-circle',
    iconClass: 'text-yellow-300',
    onClick: () => emit('execute-macro', macro),
  }))

  return [saveAsDraftAction, ...(props.groupId ? macroMenu : [])]
})
</script>

<template>
  <SplitButton
    v-if="!macrosLoaded || canUseDraft || macros?.length"
    size="large"
    variant="submit"
    type="button"
    :disabled="disabled"
    :items="actionItems"
    :addon-label="__('Additional ticket edit actions')"
    @click="$emit('submit', $event)"
  >
    {{ $t('Update') }}
  </SplitButton>
  <CommonButton
    v-else
    size="large"
    variant="submit"
    type="button"
    :disabled="disabled"
    @click="$emit('submit', $event)"
  >
    {{ $t('Update') }}
  </CommonButton>
</template>
