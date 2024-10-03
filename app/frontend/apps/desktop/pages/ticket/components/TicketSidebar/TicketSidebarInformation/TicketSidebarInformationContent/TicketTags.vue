<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { getNode } from '@formkit/core'
import { computed, nextTick, ref } from 'vue'
import { onBeforeRouteUpdate } from 'vue-router'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import { useTouchDevice } from '#shared/composables/useTouchDevice.ts'
import { useTagAssignmentAddMutation } from '#shared/entities/tags/graphql/mutations/assignment/add.api.ts'
import { useTagAssignmentRemoveMutation } from '#shared/entities/tags/graphql/mutations/assignment/remove.api.ts'
import type { TicketById } from '#shared/entities/ticket/types.ts'
import { getApolloClient } from '#shared/server/apollo/client.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonShowMoreButton from '#desktop/components/CommonShowMoreButton/CommonShowMoreButton.vue'

export interface Props {
  ticket?: TicketById
  isTicketEditable?: boolean
}

const props = defineProps<Props>()

const MAX_TAGS_VISIBLE = 5

const areAllTagsVisible = ref(false)

const tags = computed(() => {
  if (
    props.ticket?.tags &&
    props.ticket.tags.length > MAX_TAGS_VISIBLE &&
    !areAllTagsVisible.value
  )
    return props.ticket.tags.slice(0, MAX_TAGS_VISIBLE)

  return props.ticket?.tags ?? []
})

const totalTagsCount = computed(() => props.ticket?.tags?.length ?? 0)

const showMore = () => {
  areAllTagsVisible.value = true
}

onBeforeRouteUpdate(() => {
  areAllTagsVisible.value = false
})

const isNewTagVisible = ref(false)

const showNewTag = () => {
  isNewTagVisible.value = true

  nextTick(() => {
    const activate = getNode('newTag')?.context?.activate
    if (typeof activate !== 'function') return
    activate()
  })
}

const hideNewTag = () => {
  isNewTagVisible.value = false
}

const tagAssignmentAddHandler = new MutationHandler(
  useTagAssignmentAddMutation({}),
  {
    errorNotificationMessage: __('Ticket tag could not be added.'),
  },
)

// Modify ticket tags directly in the Apollo cache, rather than waiting for subscription updates.
//   This will help with any client changes being immediately visible on screen.
const modifyTagsCache = (ticketTags: string[]) => {
  if (!props.ticket) return

  getApolloClient().cache.modify({
    id: getApolloClient().cache.identify(props.ticket),
    fields: {
      tags: () => ticketTags,
    },
  })
}

const { notify } = useNotifications()

const addNewTag = (value: unknown) => {
  const tag = value as string // needed due to `onInput` signature

  if (!props.ticket?.id || !tag || tags.value.includes(tag)) return

  const ticketTags = [...(props.ticket.tags || []), tag]

  modifyTagsCache(ticketTags)

  // Always show all tags if they now exceed the visibility limit.
  //   It will make sure the newly added tag is always visible in the list.
  if (ticketTags.length > MAX_TAGS_VISIBLE) areAllTagsVisible.value = true

  tagAssignmentAddHandler
    .send({
      objectId: props.ticket.id,
      tag,
    })
    .then(() => {
      notify({
        type: NotificationTypes.Success,
        id: 'ticket-tag-added-successfully',
        message: __('Ticket tag added successfully.'),
      })
    })
}

const tagAssignmentRemoveHandler = new MutationHandler(
  useTagAssignmentRemoveMutation({}),
  {
    errorNotificationMessage: __('Ticket tag could not be removed.'),
  },
)

const removeTag = (tag: string) => {
  if (!props.ticket?.id || !tags.value.includes(tag)) return

  const ticketTags = (props.ticket.tags || []).filter(
    (tagName) => tagName !== tag,
  )

  modifyTagsCache(ticketTags)

  tagAssignmentRemoveHandler
    .send({
      objectId: props.ticket.id,
      tag,
    })
    .then(() => {
      notify({
        type: NotificationTypes.Success,
        id: 'ticket-tag-removed-successfully',
        message: __('Ticket tag removed successfully.'),
      })
    })
}

const { isTouchDevice } = useTouchDevice()

const { config } = useApplicationStore()
</script>

<template>
  <div class="flex flex-col gap-2">
    <div
      v-if="tags.length"
      class="flex w-full flex-col"
      :class="{
        'rounded-lg bg-blue-200 px-2.5 dark:bg-gray-700': isTicketEditable,
      }"
    >
      <div
        v-for="tag in tags"
        :key="tag"
        class="group flex h-10 grow items-center gap-1.5"
      >
        <CommonLabel class="grow" prefix-icon="tag">
          <CommonLink class="line-clamp-1 text-sm leading-snug" link="#">
            {{ tag }}
          </CommonLink>
        </CommonLabel>
        <CommonButton
          v-if="isTicketEditable"
          v-tooltip="$t('Remove this tag')"
          :class="{ 'opacity-0 transition-opacity': !isTouchDevice }"
          class="focus:opacity-100 group-hover:opacity-100"
          icon="x-lg"
          size="small"
          variant="remove"
          @click.stop="removeTag(tag)"
        />
      </div>
      <CommonShowMoreButton
        v-if="!areAllTagsVisible && totalTagsCount > MAX_TAGS_VISIBLE"
        class="mb-2.5 self-end"
        :entities="tags"
        :total-count="totalTagsCount"
        @click="showMore"
      />
    </div>
    <CommonLabel v-else size="small">
      {{ $t('No tags added yet.') }}
    </CommonLabel>
    <FormKit
      v-if="isNewTagVisible"
      id="newTag"
      ref="new-tag"
      type="tags"
      :label="__('Add tag')"
      :label-sr-only="true"
      :multiple="false"
      :can-create="config.tag_new"
      :exclude="ticket?.tags"
      :on-deactivate="hideNewTag"
      @input="addNewTag"
    />
    <CommonButton
      v-else-if="isTicketEditable"
      v-tooltip="$t('Add tag')"
      size="medium"
      class="self-end"
      icon="plus-square-fill"
      @click="showNewTag"
    />
  </div>
</template>
