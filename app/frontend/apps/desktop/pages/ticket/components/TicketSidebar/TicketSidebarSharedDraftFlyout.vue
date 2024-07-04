<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import type { FormRef } from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import { useTicketSharedDraftStartDeleteMutation } from '#shared/entities/ticket-shared-draft-start/graphql/mutations/ticketSharedDraftStartDelete.api.ts'
import { useTicketSharedDraftStartSingleQuery } from '#shared/entities/ticket-shared-draft-start/graphql/queries/ticketSharedDraftStartSingle.api.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import {
  MutationHandler,
  QueryHandler,
} from '#shared/server/apollo/handler/index.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonFlyout from '#desktop/components/CommonFlyout/CommonFlyout.vue'
import { closeFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'
import CommonObjectAttribute from '#desktop/components/CommonObjectAttribute/CommonObjectAttribute.vue'
import CommonObjectAttributeContainer from '#desktop/components/CommonObjectAttribute/CommonObjectAttributeContainer.vue'

const props = defineProps<{
  sharedDraftId: string
  form: FormRef | undefined
}>()

const emit = defineEmits<{
  'shared-draft-applied': [id: string]
  'shared-draft-deleted': [id: string]
}>()

// TODO: Make this more generic when the `zoom` shared draft query is made available.
const sharedDraftStartSingleQuery = new QueryHandler(
  useTicketSharedDraftStartSingleQuery(() => ({
    sharedDraftId: props.sharedDraftId,
  })),
)

const sharedDraftStartSingleResult = sharedDraftStartSingleQuery.result()

const sharedDraftStart = computed(
  () => sharedDraftStartSingleResult.value?.ticketSharedDraftStartSingle,
)

const close = () => {
  closeFlyout('shared-draft')
}

const { waitForConfirmation, waitForVariantConfirmation } = useConfirmation()

const { notify } = useNotifications()

// TODO: Make this more generic when the `zoom` shared draft mutation is made available.
const sharedDraftStartDeleteMutation = new MutationHandler(
  useTicketSharedDraftStartDeleteMutation(),
)

const { isDirty, triggerFormUpdater, updateFieldValues, values } = useForm(
  toRef(props, 'form'),
)

const deleteSharedDraft = async (sharedDraftStartId: string) => {
  const confirmed = await waitForVariantConfirmation('delete')
  if (!confirmed) return

  sharedDraftStartDeleteMutation
    .send({
      sharedDraftId: sharedDraftStartId,
    })
    .then(() => {
      // Reset shared draft internal ID, if currently set to the same value in the form.
      // TODO: Make this more generic when the `zoom` shared draft is made available.
      if (
        convertToGraphQLId(
          'Ticket::SharedDraftStart',
          Number(values.value.shared_draft_id),
        ) === sharedDraftStartId
      ) {
        updateFieldValues({
          shared_draft_id: null,
        })
      }

      notify({
        id: 'shared-draft-deleted',
        type: NotificationTypes.Success,
        message: __('Shared draft has been deleted.'),
      })

      emit('shared-draft-deleted', sharedDraftStartId)

      close()
    })
}

const applySharedDraft = async (sharedDraftStartId: string) => {
  if (isDirty.value) {
    const confirmed = await waitForConfirmation(
      __('There is existing content. Do you want to overwrite it?'),
      {
        headerTitle: __('Apply Draft'),
        buttonLabel: __('Overwrite Content'),
        buttonVariant: 'danger',
      },
    )
    if (!confirmed) return
  }

  triggerFormUpdater({
    additionalParams: {
      sharedDraftStartId,
    },
  })

  // NB: Skip notifying the user via toast, since they will immediately see the shared draft applied on screen.

  emit('shared-draft-applied', sharedDraftStartId)

  close()
}
</script>

<template>
  <CommonFlyout
    :header-title="__('Preview Shared Draft')"
    :footer-action-options="{
      actionLabel: __('Apply'),
      actionButton: { variant: 'primary' },
    }"
    header-icon="file-text"
    name="shared-draft"
  >
    <div v-if="sharedDraftStart" class="flex flex-col gap-3">
      <!-- TODO: Surely we should also display the name of the shared draft somewhere, no? -->
      <!-- <CommonObjectAttributeContainer>
        <CommonObjectAttribute :label="__('Name')">
          {{ sharedDraftStart?.name }}
        </CommonObjectAttribute>
      </CommonObjectAttributeContainer> -->

      <div class="flex items-start gap-y-3">
        <CommonObjectAttributeContainer
          v-if="sharedDraftStart?.updatedBy"
          class="grow"
        >
          <CommonObjectAttribute :label="__('Author')">
            <div class="flex items-center gap-1.5">
              <CommonUserAvatar
                :entity="sharedDraftStart?.updatedBy"
                size="small"
              />
              <CommonLabel>{{
                sharedDraftStart.updatedBy.fullname
              }}</CommonLabel>
            </div>
          </CommonObjectAttribute>
        </CommonObjectAttributeContainer>

        <CommonObjectAttributeContainer class="grow">
          <CommonObjectAttribute :label="__('Last changed')">
            <CommonDateTime :date-time="sharedDraftStart?.updatedAt" />
          </CommonObjectAttribute>
        </CommonObjectAttributeContainer>
      </div>

      <!--
        TODO: Think about showing more attributes here, since the body might not be present at all in the draft.
          But keep in mind this might not be easily possible, since we are missing some information from the query.
          For example, we have only `owner_id`/`state_id`/`priority_id`, what about lookup objects?!
      -->
      <CommonObjectAttributeContainer v-if="sharedDraftStart?.content.body">
        <CommonObjectAttribute :label="__('Text')">
          <!-- eslint-disable vue/no-v-html -->
          <span v-html="sharedDraftStart.content.body" />
        </CommonObjectAttribute>
      </CommonObjectAttributeContainer>
    </div>

    <template #footer>
      <div class="flex items-center justify-end gap-4">
        <CommonButton size="large" variant="secondary" @click="close">
          {{ $t('Cancel & Go Back') }}
        </CommonButton>
        <CommonButton
          size="large"
          variant="danger"
          @click="deleteSharedDraft(sharedDraftId)"
        >
          {{ $t('Delete') }}
        </CommonButton>
        <CommonButton
          size="large"
          variant="primary"
          @click="applySharedDraft(sharedDraftId)"
        >
          {{ $t('Apply') }}
        </CommonButton>
      </div>
    </template>
  </CommonFlyout>
</template>
