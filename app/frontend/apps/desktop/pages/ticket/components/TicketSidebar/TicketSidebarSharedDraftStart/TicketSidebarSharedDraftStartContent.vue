<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { createMessage, getNode } from '@formkit/core'
import { computed, ref } from 'vue'
import { useRoute } from 'vue-router'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import { useTicketSharedDraftStartCreateMutation } from '#shared/entities/ticket-shared-draft-start/graphql/mutations/ticketSharedDraftStartCreate.api.ts'
import { useTicketSharedDraftStartUpdateMutation } from '#shared/entities/ticket-shared-draft-start/graphql/mutations/ticketSharedDraftStartUpdate.api.ts'
import type { TicketSharedDraftStartListQuery } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import type { ObjectLike } from '#shared/types/utils.ts'
import { removeSignatureFromBody } from '#shared/utils/dom.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import { useTicketSharedDraft } from '#desktop/pages/ticket/composables/useTicketSharedDraft.ts'
import type { TicketSidebarContentProps } from '#desktop/pages/ticket/types/sidebar.ts'

import TicketSidebarContent from '../TicketSidebarContent.vue'

interface Props extends TicketSidebarContentProps {
  sharedDraftStartList: TicketSharedDraftStartListQuery['ticketSharedDraftStartList']
}

const props = defineProps<Props>()

const persistentStates = defineModel<ObjectLike>({ required: true })

const groupId = computed(() =>
  convertToGraphQLId('Group', Number(props.context.formValues.group_id)),
)

const currentSharedDraftId = computed(() =>
  convertToGraphQLId(
    'Ticket::SharedDraftStart',
    Number(props.context.formValues.shared_draft_id),
  ),
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
  body: removeSignatureFromBody(props.context.formValues.body),
})

const route = useRoute()

const sharedDraftTitleNodeId = computed(
  () => `sharedDraftTitle-${route.meta.taskbarTabEntityKey}`,
)

const createSharedDraft = async () => {
  const sharedDraftTitleNode = getNode(sharedDraftTitleNodeId.value)

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

const { openSharedDraftFlyout } = useTicketSharedDraft(
  props.context.setSkipNextStateUpdate,
)

const openFlyout = (sharedDraftStartId: string) => {
  openSharedDraftFlyout('start', sharedDraftStartId, props.context.form)
}
</script>

<template>
  <TicketSidebarContent
    v-model="persistentStates.scrollPosition"
    :title="sidebarPlugin.title"
    :icon="sidebarPlugin.icon"
  >
    <FormKit
      :id="sharedDraftTitleNodeId"
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
              class="line-clamp-1 text-stone-200! dark:text-neutral-500!"
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
        class="text-stone-200! dark:text-neutral-500!"
        size="small"
      >
        {{ $t('No shared drafts yet') }}
      </CommonLabel>
    </div>
  </TicketSidebarContent>
</template>
