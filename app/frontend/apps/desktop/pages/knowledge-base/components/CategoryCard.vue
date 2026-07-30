<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { isEqual } from 'lodash-es'
import { storeToRefs } from 'pinia'
import { computed } from 'vue'

import CommonBadge from '#shared/components/CommonBadge/CommonBadge.vue'
import CommonIcon from '#shared/components/CommonIcon/CommonIcon.vue'
import CommonLabel from '#shared/components/CommonLabel/CommonLabel.vue'
import type { Link } from '#shared/types/router.ts'

import CommonActionMenu from '#desktop/components/CommonActionMenu/CommonActionMenu.vue'
import CommonDivider from '#desktop/components/CommonDivider/CommonDivider.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import { knowledgeBaseBrowseRoute } from '#desktop/entities/knowledge-base/utils/routeLocation.ts'
import KnowledgeBaseIconStatus from '#desktop/pages/knowledge-base/components/KnowledgeBaseIconStatus.vue'

import { useKnowledgeBaseAccess } from '../../../entities/knowledge-base/composables/useKnowledgeBaseAccess.ts'
import { useKnowledgeBaseStore } from '../../../entities/knowledge-base/stores/knowledgeBase.ts'

import type { KnowledgeBaseCategoryCompact } from '../types.ts'

const props = withDefaults(defineProps<KnowledgeBaseCategoryCompact>(), {
  subcategoryCount: 0,
  answerCount: 0,
})

const { activeLocale } = storeToRefs(useKnowledgeBaseStore())

const link = computed<Link | undefined>((currentLink) => {
  // The category route pins the locale; without it there is no valid target
  //   yet (the active locale resolves from the knowledge base query).
  if (!props.id || !activeLocale.value) return undefined

  const newLink = knowledgeBaseBrowseRoute(activeLocale.value, props.id)

  if (currentLink && isEqual(currentLink, newLink)) return currentLink

  return newLink
})

const { canEdit } = useKnowledgeBaseAccess()

const actions: MenuItem[] = [
  { key: 'link1', link: '/link1', label: __('Add Answer'), icon: 'kba-add' },
  { key: 'link2', link: '/link2', label: __('Add sub-category'), icon: 'folder-plus' },
  { key: 'link3', link: '/link3', label: __('Remove category'), icon: 'trash3' },
]
</script>

<template>
  <li>
    <component
      :is="link ? 'CommonLink' : 'div'"
      :link="link"
      :internal="link ? true : undefined"
      class="group relative flex size-full flex-col rounded-xl! bg-blue-200 px-3 pt-6 pb-2.25 hover:bg-blue-600 active:bg-blue-800! dark:bg-gray-500 hover:dark:bg-blue-900"
    >
      <CommonBadge
        v-if="translationMissing"
        v-tooltip="$t('No translation for this locale available')"
        variant="warning"
        size="xs"
        rounded
        class="absolute inset-s-3 top-3 flex aspect-square items-center justify-center p-1! group-hover:bg-black group-hover:text-blue-600 group-active:bg-white! group-hover:dark:bg-white group-hover:dark:text-blue-900"
      >
        <CommonIcon name="translate" size="xs" decorative />
      </CommonBadge>
      <div class="flex min-h-26.75 flex-col items-center gap-3">
        <!-- set default icon for now -->
        <!-- :name="categoryIcon" -->
        <KnowledgeBaseIconStatus name="folder" size="medium" :status="visibility" />

        <div class="flex min-h-11 w-full items-center justify-center">
          <CommonLabel
            size="medium"
            class="line-clamp-2! text-center text-black! group-active:text-white! dark:text-white!"
          >
            {{ title }}
          </CommonLabel>
        </div>
      </div>

      <CommonDivider />

      <div class="flex w-full items-center justify-between pt-2.25">
        <div class="flex items-center gap-3">
          <div
            v-tooltip="$t('Category count: %s', subcategoryCount)"
            class="flex items-center gap-1"
          >
            <CommonIcon
              name="folder"
              size="small"
              class="text-stone-200 group-hover:text-black group-active:text-white dark:text-neutral-500 group-hover:dark:text-white dark:group-active:text-white"
            />
            <CommonBadge
              class="cursor-pointer! px-1.5 py-0.5 text-center leading-snug font-bold group-hover:bg-black group-hover:text-blue-600 group-active:bg-white! group-hover:dark:bg-white group-hover:dark:text-blue-900"
              size="xs"
              rounded
            >
              {{ subcategoryCount }}
            </CommonBadge>
          </div>
          <div v-tooltip="$t('Answer count: %s', answerCount)" class="flex items-center gap-1">
            <CommonIcon
              name="file-richtext"
              size="small"
              class="text-stone-200 group-hover:text-black group-active:text-white dark:text-neutral-500 group-hover:dark:text-white dark:group-active:text-white"
            />
            <CommonBadge
              class="cursor-pointer! px-1.5 py-0.5 text-center leading-snug font-bold group-hover:bg-black group-hover:text-blue-600 group-active:bg-white! group-hover:dark:bg-white group-hover:dark:text-blue-900"
              size="xs"
              rounded
            >
              {{ answerCount }}
            </CommonBadge>
          </div>
        </div>
        <!-- TODO: Make available when working on actions -->
        <CommonActionMenu
          v-if="false && canEdit"
          data-attribute="action"
          button-size="small"
          :actions="actions"
        />
      </div>
    </component>
  </li>
</template>
