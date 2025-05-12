<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

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
import type {
  TicketSharedDraftStartSingleQuery,
  TicketSharedDraftZoomShowQuery,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import {
  MutationHandler,
  QueryHandler,
} from '#shared/server/apollo/handler/index.ts'
import type {
  OperationMutationFunction,
  OperationQueryFunction,
} from '#shared/types/server/apollo/handler'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonFlyout from '#desktop/components/CommonFlyout/CommonFlyout.vue'
import { closeFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'
import CommonObjectAttribute from '#desktop/components/CommonObjectAttribute/CommonObjectAttribute.vue'
import CommonObjectAttributeContainer from '#desktop/components/CommonObjectAttribute/CommonObjectAttributeContainer.vue'

const props = defineProps<{
  sharedDraftId: string
  form: FormRef | undefined
  draftType: 'start' | 'detail-view'
  metaInformationQuery: OperationQueryFunction
  deleteMutation: OperationMutationFunction
  setSkipNextStateUpdate?: (skip: boolean) => void
}>()

const emit = defineEmits<{
  'shared-draft-applied': [id: string]
  'shared-draft-deleted': [id: string]
}>()

const { metaInformationQuery, deleteMutation } = props

const flyoutName = 'shared-draft'

const metaInformationQueryHandler = new QueryHandler(
  metaInformationQuery({
    sharedDraftId: props.sharedDraftId,
  }),
)

const metaInformationQueryResult = metaInformationQueryHandler.result()

const sharedDraft = computed(() => {
  if (props.draftType === 'start') {
    return metaInformationQueryResult.value
      ?.ticketSharedDraftStartSingle as TicketSharedDraftStartSingleQuery['ticketSharedDraftStartSingle']
  }

  return metaInformationQueryResult.value
    ?.ticketSharedDraftZoomShow as TicketSharedDraftZoomShowQuery['ticketSharedDraftZoomShow']
})

const sharedDraftContent = computed(() => {
  if (props.draftType === 'start') {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const content: any =
      sharedDraft.value as TicketSharedDraftStartSingleQuery['ticketSharedDraftStartSingle']

    return content.content.body
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const newArticle: any =
    sharedDraft.value as TicketSharedDraftZoomShowQuery['ticketSharedDraftZoomShow']

  return newArticle.newArticle.body
})

const close = () => {
  closeFlyout(flyoutName)
}

const { waitForConfirmation, waitForVariantConfirmation } = useConfirmation()

const { notify } = useNotifications()

const sharedDrafteleteMutation = new MutationHandler(deleteMutation({}))

const { isDirty, triggerFormUpdater, updateFieldValues, values } = useForm(
  toRef(props, 'form'),
)

const deleteSharedDraft = async (sharedDraftId: string) => {
  const confirmed = await waitForVariantConfirmation('delete')
  if (!confirmed) return

  sharedDrafteleteMutation
    .send({
      sharedDraftId,
    })
    .then(() => {
      // Reset shared draft internal ID, if currently set to the same value in the form.
      if (
        (props.draftType === 'start' &&
          convertToGraphQLId(
            'Ticket::SharedDraftStart',
            Number(values.value.shared_draft_id),
          ) === sharedDraftId) ||
        (props.draftType === 'detail-view' &&
          convertToGraphQLId(
            'Ticket::SharedDraftZoom',
            Number(values.value.shared_draft_id),
          ) === sharedDraftId)
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

      emit('shared-draft-deleted', sharedDraftId)

      close()
    })
}

const applySharedDraft = async (sharedDraftId: string) => {
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

  const additionalParams = {
    sharedDraftId,
    draftType: props.draftType,
  }

  // Skip subscription for the current taskbar tab, to avoid unnecessary form updater requests.
  props.setSkipNextStateUpdate?.(true)

  triggerFormUpdater({ additionalParams })

  // NB: Skip notifying the user via toast, since they will immediately see the shared draft applied on screen.

  emit('shared-draft-applied', sharedDraftId)

  close()
}

const headerTitle = computed(() => {
  if (props.draftType === 'start') {
    return __('Preview Shared Draft')
  }

  return __('Apply Shared Draft')
})
</script>

<template>
  <CommonFlyout
    :header-title="headerTitle"
    :footer-action-options="{
      actionLabel: __('Apply'),
      actionButton: { variant: 'primary' },
    }"
    header-icon="file-text"
    :name="flyoutName"
    @activated="metaInformationQueryHandler.refetch()"
  >
    <div v-if="sharedDraft" class="flex flex-col gap-3">
      <!-- TODO: Surely we should also display the name of the shared draft somewhere, no? -->
      <!-- <CommonObjectAttributeContainer>
        <CommonObjectAttribute :label="__('Name')">
          {{ sharedDraft?.name }}
        </CommonObjectAttribute>
      </CommonObjectAttributeContainer> -->

      <div class="flex items-start gap-y-3">
        <CommonObjectAttributeContainer
          v-if="sharedDraft?.updatedBy"
          class="grow"
        >
          <CommonObjectAttribute :label="__('Author')">
            <div class="flex items-center gap-1.5">
              <CommonUserAvatar :entity="sharedDraft?.updatedBy" size="small" />
              <CommonLabel>{{ sharedDraft.updatedBy.fullname }}</CommonLabel>
            </div>
          </CommonObjectAttribute>
        </CommonObjectAttributeContainer>

        <CommonObjectAttributeContainer class="grow">
          <CommonObjectAttribute :label="__('Last changed')">
            <CommonDateTime :date-time="sharedDraft?.updatedAt" />
          </CommonObjectAttribute>
        </CommonObjectAttributeContainer>
      </div>

      <!--
        TODO: Think about showing more attributes here, since the body might not be present at all in the draft.
          But keep in mind this might not be easily possible, since we are missing some information from the query.
          For example, we have only `owner_id`/`state_id`/`priority_id`, what about lookup objects?!
      -->
      <CommonObjectAttributeContainer v-if="sharedDraftContent">
        <CommonObjectAttribute :label="__('Text')">
          <!-- eslint-disable vue/no-v-html -->
          <span v-html="sharedDraftContent" />
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
