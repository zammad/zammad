<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref } from 'vue'
import { onBeforeRouteUpdate } from 'vue-router'

import { useTouchDevice } from '#shared/composables/useTouchDevice.ts'
import type { TicketById } from '#shared/entities/ticket/types.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonShowMoreButton from '#desktop/components/CommonShowMoreButton/CommonShowMoreButton.vue'
import { useTagAssignment } from '#desktop/entities/tags/composables/useTagAssignment.ts'

export interface Props {
  ticket?: TicketById
  isTicketEditable?: boolean
}

const props = defineProps<Props>()

const MAX_TAGS_VISIBLE = 5

const areAllTagsVisible = ref(false)

const tags = computed(() => {
  if (props.ticket?.tags && props.ticket.tags.length > MAX_TAGS_VISIBLE && !areAllTagsVisible.value)
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

const { addTag, removeTag, newTagId, isNewTagVisible, showNewTag, hideNewTag } = useTagAssignment({
  entity: () => props.ticket,
  tags: () => props.ticket?.tags ?? [],
})

const addNewTag = (value: unknown) => {
  const exceedsLimit = totalTagsCount.value >= MAX_TAGS_VISIBLE

  // Always show all tags if they now exceed the visibility limit.
  //   It will make sure the newly added tag is always visible in the list.
  if (addTag(value) && exceedsLimit) areAllTagsVisible.value = true
}

const { isTouchDevice } = useTouchDevice()

const { config } = useApplicationStore()

// TODO: Add proper quick search handler for tag search when ready.
const getTagSearchLink = (tag: string) => ({
  name: 'Search',
  params: {
    searchTerm: `tags:"${tag}"`,
  },
  query: {
    entity: 'Ticket',
  },
})
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
      <div v-for="tag in tags" :key="tag" class="group flex h-10 grow items-center gap-1.5">
        <CommonLabel class="grow" prefix-icon="tag">
          <CommonLink class="line-clamp-1" :link="getTagSearchLink(tag)" size="medium">
            {{ tag }}
          </CommonLink>
        </CommonLabel>
        <CommonButton
          v-if="isTicketEditable"
          v-tooltip="$t('Remove this tag')"
          :class="{ 'opacity-0 transition-opacity': !isTouchDevice }"
          class="group-hover:opacity-100 focus:opacity-100"
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
      :id="newTagId"
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
