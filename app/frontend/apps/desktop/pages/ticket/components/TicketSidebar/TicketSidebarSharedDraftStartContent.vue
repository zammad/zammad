<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { createMessage, getNode } from '@formkit/core'
import { computed, ref } from 'vue'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import { useTicketSharedDraftStart } from '#shared/entities/ticket-shared-draft-start/composables/useTicketSharedDraftStart.ts'
import { useTicketSharedDraftStartCreateMutation } from '#shared/entities/ticket-shared-draft-start/graphql/mutations/ticketSharedDraftStartCreate.api.ts'
import { useTicketSharedDraftStartUpdateMutation } from '#shared/entities/ticket-shared-draft-start/graphql/mutations/ticketSharedDraftStartUpdate.api.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import {
  GraphQLErrorTypes,
  type GraphQLHandlerError,
} from '#shared/types/error.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import { useFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'

import TicketSidebarContent from './TicketSidebarContent.vue'

import type { TicketSidebarContentProps } from '../types.ts'

const props = defineProps<TicketSidebarContentProps>()

const groupId = computed(() =>
  convertToGraphQLId('Group', Number(props.context.formValues.group_id)),
)

const currentSharedDraftId = computed(() =>
  convertToGraphQLId(
    'Ticket::SharedDraftStart',
    Number(props.context.formValues.shared_draft_id),
  ),
)

// Silence query error notification in the frontend in case of unknown errors.
//   The query may raise a non-specific error if the group has inactive shared drafts.
//   FIXME: Check if it's possible to silence the console error too.
const errorCallback = (error: GraphQLHandlerError) =>
  error.type !== GraphQLErrorTypes.UnknownError

const { sharedDraftStartList } = useTicketSharedDraftStart(
  groupId,
  errorCallback,
)

const sharedDraftTitle = ref('')

const { notify } = useNotifications()

const sharedDraftStartCreateMutation = new MutationHandler(
  useTicketSharedDraftStartCreateMutation(),
)

const unsupportedFields = [
  'articleSenderType',
  'attachments',
  'group_id',
  'security',
  'shared_draft_id',
  'ticket_duplicate_detection',
]

const supportedFields = () =>
  Object.fromEntries(
    Object.entries(props.context.formValues).filter(
      ([field]) => !unsupportedFields.includes(field),
    ),
  )

const sharedDraftContent = () => ({
  ...supportedFields(),
  formSenderType: props.context.formValues.articleSenderType, // different key
  cc: ((props.context.formValues.cc as string[]) || []).join(', '),
  tags: ((props.context.formValues.tags as string[]) || []).join(', '),
})

const createSharedDraft = () => {
  const sharedDraftTitleNode = getNode('sharedDraftTitle')
  if (!sharedDraftTitleNode) return

  // Trigger field validation.
  sharedDraftTitleNode.store.set(
    createMessage({
      key: 'submitted',
      value: true,
      visible: false,
    }),
  )

  // Check if the field passed validation.
  if (Object.keys(sharedDraftTitleNode.context?.messages || {}).length) return

  sharedDraftStartCreateMutation
    .send({
      name: sharedDraftTitle.value.trim(),
      input: {
        formId: props.context.form?.formId as string,
        groupId: groupId.value,
        content: sharedDraftContent(),
      },
    })
    .then(() => {
      sharedDraftTitleNode.reset()

      notify({
        id: 'shared-draft-created',
        type: NotificationTypes.Success,
        message: __('Shared draft has been created successfully.'),
      })
    })
}

const sharedDraftStartUpdateMutation = new MutationHandler(
  useTicketSharedDraftStartUpdateMutation(),
)

const updateSharedDraft = () => {
  if (!currentSharedDraftId.value) return

  sharedDraftStartUpdateMutation
    .send({
      sharedDraftId: currentSharedDraftId.value,
      input: {
        formId: props.context.form?.formId as string,
        groupId: groupId.value,
        content: sharedDraftContent(),
      },
    })
    .then(() => {
      notify({
        id: 'shared-draft-updated',
        type: NotificationTypes.Success,
        message: __('Shared draft has been updated successfully.'),
      })
    })
}

const sharedDraftFlyout = useFlyout({
  name: 'shared-draft',
  component: () => import('./TicketSidebarSharedDraftFlyout.vue'),
})

const openFlyout = (sharedDraftStartId: string) => {
  sharedDraftFlyout.open({
    sharedDraftId: sharedDraftStartId,
    form: props.context.form,
  })
}
</script>

<template>
  <TicketSidebarContent :title="__('Shared Drafts')" icon="file-text">
    <FormKit
      id="sharedDraftTitle"
      v-model="sharedDraftTitle"
      type="text"
      :label="__('Create a shared draft')"
      :placeholder="__('Name')"
      validation="required:trim"
      link="/"
      link-icon="plus-square-fill"
      :link-label="__('Create Shared Draft')"
      @link-click.prevent="createSharedDraft"
      @keypress.enter.prevent="createSharedDraft"
    />

    <div class="py-1">
      <div
        v-if="sharedDraftStartList?.length"
        class="flex flex-col divide-y divide-solid divide-neutral-100 dark:divide-gray-900"
      >
        <div
          v-for="sharedDraftStart in sharedDraftStartList"
          :key="sharedDraftStart.id"
          class="flex items-center gap-1.5 py-2.5"
        >
          <div class="flex grow flex-col">
            <CommonLink
              v-tooltip="sharedDraftStart.name"
              link="#"
              class="line-clamp-1"
              :aria-label="$t('Preview Shared Draft')"
              @click.prevent="openFlyout(sharedDraftStart.id)"
              >{{ sharedDraftStart.name }}</CommonLink
            >
            <CommonLabel
              class="line-clamp-1 text-stone-200 dark:text-neutral-500"
              size="small"
            >
              <CommonDateTime :date-time="sharedDraftStart.updatedAt" />
              <template v-if="sharedDraftStart.updatedBy">
                <span v-tooltip="sharedDraftStart.updatedBy.fullname">
                  &bull; {{ sharedDraftStart.updatedBy.fullname }}
                </span>
              </template>
            </CommonLabel>
          </div>
          <CommonButton
            v-if="currentSharedDraftId === sharedDraftStart.id"
            v-tooltip="__('Update Shared Draft')"
            variant="submit"
            size="small"
            icon="arrow-repeat"
            @click="updateSharedDraft"
          />
        </div>
      </div>
      <CommonLabel
        v-else
        class="text-stone-200 dark:text-neutral-500"
        size="small"
      >
        {{ $t('No shared drafts yet') }}
      </CommonLabel>
    </div>
  </TicketSidebarContent>
</template>
