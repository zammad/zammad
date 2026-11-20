<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->
<script lang="ts" setup>
import { computed } from 'vue'

import CommonLabel from '#shared/components/CommonLabel/CommonLabel.vue'
import CommonLink from '#shared/components/CommonLink/CommonLink.vue'
import { useTouchDevice } from '#shared/composables/useTouchDevice.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonSectionCollapse from '#desktop/components/CommonSectionCollapse/CommonSectionCollapse.vue'
import { useTagAssignment } from '#desktop/entities/tags/composables/useTagAssignment.ts'
import { tagSearchRoute } from '#desktop/entities/tags/utils/routeLocation.ts'

import type { KnowledgeBaseAnswerHeader } from '../../../types.ts'

interface Props {
  answer: KnowledgeBaseAnswerHeader
  // Tags are written straight onto the answer, the moment they are added or removed - the same as
  //   the ticket detail view's own tag section does. They are deliberately not part of the edit
  //   form: nothing about them is submitted with it, which also means they are not part of its
  //   auto-saved draft and not covered by "Discard your unsaved changes" - the same as the linked
  //   tickets right below them.
  editable?: boolean
}

const props = withDefaults(defineProps<Props>(), { editable: false })

const tags = computed(
  () => props.answer.tags?.map((tag) => ({ label: tag, link: tagSearchRoute(tag) })) ?? [],
)

const { isTouchDevice } = useTouchDevice()
const { config } = useApplicationStore()

const currentTags = computed(() => props.answer.tags ?? [])

const { addTag, removeTag, newTagId, isNewTagVisible, showNewTag, hideNewTag } = useTagAssignment({
  entity: () => props.answer,
  tags: () => currentTags.value,
})
</script>

<template>
  <CommonSectionCollapse id="knowledge-base-tags" :title="__('Tags')">
    <template #default="{ headerId }">
      <div class="flex flex-col gap-2">
        <ul
          v-if="tags.length"
          :aria-labelledby="headerId"
          class="flex w-full flex-col rounded-lg bg-blue-200 px-2.5 dark:bg-gray-700"
        >
          <li v-for="tag in tags" :key="tag.label" class="group flex items-center gap-1.5 py-2.5">
            <CommonLabel class="grow" prefix-icon="tag">
              <CommonLink class="line-clamp-1" :link="tag.link" size="medium">
                {{ tag.label }}
              </CommonLink>
            </CommonLabel>

            <!-- Hover-only on a pointer device, always there on a touch one, which has no hover to
                 reveal it with. -->
            <CommonButton
              v-if="editable"
              v-tooltip="$t('Remove this tag')"
              :class="{ 'opacity-0 transition-opacity': !isTouchDevice }"
              class="group-hover:opacity-100 focus:opacity-100"
              icon="x-lg"
              size="small"
              variant="remove"
              @click.stop="removeTag(tag.label)"
            />
          </li>
        </ul>

        <CommonLabel v-else size="small">
          {{ $t('No tags added yet.') }}
        </CommonLabel>

        <FormKit
          v-if="editable && isNewTagVisible"
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
          v-else-if="editable"
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
