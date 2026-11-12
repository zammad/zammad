<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { getNode } from '@formkit/core'
import { computed, nextTick, ref } from 'vue'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import { useTouchDevice } from '#shared/composables/useTouchDevice.ts'
import { useTagAssignmentAddMutation } from '#shared/entities/tags/graphql/mutations/assignment/add.api.ts'
import { useTagAssignmentRemoveMutation } from '#shared/entities/tags/graphql/mutations/assignment/remove.api.ts'
import { getApolloClient } from '#shared/server/apollo/client.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonSectionCollapse from '#desktop/components/CommonSectionCollapse/CommonSectionCollapse.vue'
import type { ChatConversationSession } from '#desktop/entities/chat/types.ts'

interface Props {
  session: Pick<ChatConversationSession, 'id' | 'internalId' | 'tags'>
}

interface TagEdit {
  tag: string
  add: boolean
}

const props = defineProps<Props>()

const { notify } = useNotifications()
const { isTouchDevice } = useTouchDevice()
const { config } = useApplicationStore()

const applyEdit = (tags: string[], { tag, add }: TagEdit) => {
  if (!add) return tags.filter((name) => name !== tag)

  return tags.includes(tag) ? tags : [...tags, tag]
}

const addMutation = new MutationHandler(useTagAssignmentAddMutation({}), {
  errorNotificationMessage: __('The tag could not be added.'),
})

const removeMutation = new MutationHandler(useTagAssignmentRemoveMutation({}), {
  errorNotificationMessage: __('The tag could not be removed.'),
})

const isNewTagVisible = ref(false)

// Every open window has its own field.
const newTagId = `chatSession${props.session.internalId}NewTag`

const hideNewTag = () => {
  isNewTagVisible.value = false
}

const showNewTag = async () => {
  isNewTagVisible.value = true

  await nextTick()

  const activate = getNode(newTagId)?.context?.activate

  if (typeof activate === 'function') activate()
}

const currentTags = computed(() => props.session.tags)

// What the server stored, and the edits still on their way on top: an edit that fails drops out
//   of them without undoing a later one.
let storedTags: string[] = []
let pendingEdits: TagEdit[] = []

const showTags = () => {
  const client = getApolloClient()
  const tags = pendingEdits.reduce(applyEdit, storedTags)

  client.cache.modify({
    id: client.cache.identify({ __typename: 'ChatSession', id: props.session.id }),
    fields: { tags: () => tags },
  })
}

const sendEdit = async (edit: TagEdit) => {
  const variables = { objectId: props.session.id, tag: edit.tag }

  try {
    if (edit.add) await addMutation.send(variables)
    else await removeMutation.send(variables)

    storedTags = applyEdit(storedTags, edit)

    notify({
      type: NotificationTypes.Success,
      id: edit.add ? 'chat-session-tag-added' : 'chat-session-tag-removed',
      message: edit.add ? __('Tag added successfully.') : __('Tag removed successfully.'),
    })
  } catch {
    // The handler reports the failure itself.
  }

  pendingEdits = pendingEdits.filter((pending) => pending !== edit)

  showTags()
}

// One at a time: the server takes them in the agent's order, and an earlier call superseded on the
//   same mutation would fail without its notification.
let lastEditSent = Promise.resolve()

const editTags = (edit: TagEdit) => {
  if (!pendingEdits.length) storedTags = currentTags.value

  pendingEdits = [...pendingEdits, edit]

  showTags()

  lastEditSent = lastEditSent.then(() => sendEdit(edit))
}

const addTag = (value: unknown) => {
  const tag = value as string

  if (!tag || currentTags.value.includes(tag)) return

  editTags({ tag, add: true })
}

const removeTag = (tag: string) => {
  editTags({ tag, add: false })
}
</script>

<template>
  <CommonSectionCollapse :id="`chat-session-${session.internalId}-tags`" :title="__('Tags')">
    <template #default="{ headerId }">
      <div class="flex flex-col gap-2">
        <ul
          v-if="currentTags.length"
          :aria-labelledby="headerId"
          class="flex w-full flex-col rounded-lg bg-blue-200 p-1 dark:bg-gray-700"
        >
          <li v-for="tag in currentTags" :key="tag" class="group flex items-center gap-1.5 p-2.5">
            <CommonLabel class="line-clamp-1 grow" prefix-icon="tag">{{ tag }}</CommonLabel>

            <!-- Hover-only on a pointer device, always there on a touch one. -->
            <CommonButton
              v-tooltip="$t('Remove this tag')"
              :class="{ 'opacity-0 transition-opacity': !isTouchDevice }"
              class="group-hover:opacity-100 focus:opacity-100"
              icon="x-lg"
              size="small"
              variant="remove"
              @click.stop="removeTag(tag)"
            />
          </li>
        </ul>

        <CommonLabel v-else size="small">
          {{ $t('No tags added yet.') }}
        </CommonLabel>

        <FormKit
          v-if="isNewTagVisible"
          :id="newTagId"
          type="tags"
          :label="__('Add tag')"
          :label-sr-only="true"
          :multiple="false"
          :can-create="config.tag_new"
          :exclude="currentTags"
          :on-deactivate="hideNewTag"
          @input="addTag"
        />

        <CommonButton
          v-else
          v-tooltip="$t('Add tag')"
          size="medium"
          class="self-end"
          icon="plus-square-fill"
          @click="showNewTag"
        />
      </div>
    </template>
  </CommonSectionCollapse>
</template>
