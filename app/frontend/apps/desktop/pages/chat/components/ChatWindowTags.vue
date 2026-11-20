<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { useTouchDevice } from '#shared/composables/useTouchDevice.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonSectionCollapse from '#desktop/components/CommonSectionCollapse/CommonSectionCollapse.vue'
import type { ChatConversationSession } from '#desktop/entities/chat/types.ts'
import { useTagAssignment } from '#desktop/entities/tags/composables/useTagAssignment.ts'

interface Props {
  session: Pick<ChatConversationSession, 'id' | 'internalId' | 'tags'>
}

const props = defineProps<Props>()

const { isTouchDevice } = useTouchDevice()
const { config } = useApplicationStore()

const currentTags = computed(() => props.session.tags)

const { addTag, removeTag, newTagId, isNewTagVisible, showNewTag, hideNewTag } = useTagAssignment({
  entity: () => ({ __typename: 'ChatSession', id: props.session.id }),
  tags: () => currentTags.value,
})
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
