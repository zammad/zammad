<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { isEqual } from 'lodash-es'
import { storeToRefs } from 'pinia'
import { computed } from 'vue'
import { useRouter } from 'vue-router'

import CommonBadge from '#shared/components/CommonBadge/CommonBadge.vue'
import CommonIcon from '#shared/components/CommonIcon/CommonIcon.vue'
import CommonLabel from '#shared/components/CommonLabel/CommonLabel.vue'
import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'
import type { Link } from '#shared/types/router.ts'

import CommonActionMenu from '#desktop/components/CommonActionMenu/CommonActionMenu.vue'
import CommonDivider from '#desktop/components/CommonDivider/CommonDivider.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import { useKnowledgeBaseCategoryDelete } from '#desktop/entities/knowledge-base/composables/useKnowledgeBaseCategoryDelete.ts'
import { useKnowledgeBaseStore } from '#desktop/entities/knowledge-base/stores/knowledgeBase.ts'
import {
  knowledgeBaseAnswerCreateRoute,
  knowledgeBaseBrowseRoute,
} from '#desktop/entities/knowledge-base/utils/routeLocation.ts'
import KnowledgeBaseIconStatus from '#desktop/pages/knowledge-base/components/KnowledgeBaseIconStatus.vue'

import {
  openKnowledgeBaseCategoryAddFlyout,
  openKnowledgeBaseCategoryEditFlyout,
} from '../../composables/useKnowledgeBaseCategoryFlyout.ts'

import type { KnowledgeBaseCategoryCompact } from '../../types.ts'

const props = withDefaults(
  defineProps<
    KnowledgeBaseCategoryCompact & {
      // Whether the sorting bar is up, in any of its modes. The card is then a tile in a listing
      //   being arranged and nothing else: no menu, no counts, no link — see the template.
      isSorting?: boolean
      // Whether this listing is the one being dragged, i.e. `isSorting` in the manual mode. Only
      //   that mode gives the card a grip and a drag cursor; the automatic ones arrange it
      //   themselves.
      isRearranging?: boolean
      // DOM id of the grid item, which `aria-activedescendant` on the grid points at while it is
      //   navigated by keyboard. Spelled out rather than let through as a fallthrough attribute:
      //   `id` is a prop here (the category's), so an `id` attribute would overwrite it.
      listItemId?: string
      //
      isFocused: boolean
      isSelected: boolean
    }
  >(),
  {
    subcategoryCount: 0,
    answerCount: 0,
  },
)

const { activeLocale, iconSet } = storeToRefs(useKnowledgeBaseStore())

const router = useRouter()

const link = computed<Link | undefined>((currentLink) => {
  // The category route pins the locale; without it there is no valid target
  //   yet (the active locale resolves from the knowledge base query).
  // No target at all while the bar is up: opening a category from underneath it would abandon a
  //   mode or an order the editor has not saved yet — a picked mode counts as much as a drag.
  if (!props.id || !activeLocale.value || props.isSorting) return undefined

  const newLink = knowledgeBaseBrowseRoute(activeLocale.value, props.id)

  if (currentLink && isEqual(currentLink, newLink)) return currentLink

  return newLink
})

const { confirmCategoryDelete } = useKnowledgeBaseCategoryDelete()

// Gated per record, not by the global editor permission: granular permissions can limit an
//   editor to a part of the tree, and offering an action the mutation then refuses is worse
//   than not offering it (the legacy stack gates per record too).
const actions = computed<MenuItem[]>(() => {
  // Not while the bar is up: the card is then a tile in a listing being arranged, a drag handle
  //   in the manual mode, and every one of the menu's entries leads away from the unsaved order.
  if (props.isSorting) return []

  return [
    {
      key: 'add-answer',
      label: __('Add answer'),
      icon: 'kba-add',
      show: () => props.policy.createAnswer,
      onClick: () => {
        if (!activeLocale.value) return

        router.push(
          knowledgeBaseAnswerCreateRoute(activeLocale.value, getIdFromGraphQLId(props.id)),
        )
      },
    },
    {
      key: 'add-subcategory',
      label: __('Add sub-category'),
      icon: 'folder-plus',
      show: () => props.policy.createSubcategory,
      onClick: () => openKnowledgeBaseCategoryAddFlyout({ parentId: props.id }),
    },
    {
      key: 'edit-category',
      label: __('Edit category'),
      icon: 'pencil',
      show: () => props.policy.update,
      onClick: () =>
        openKnowledgeBaseCategoryEditFlyout({
          id: props.id,
          title: props.title,
          categoryIcon: props.categoryIcon,
        }),
    },
    {
      key: 'delete-category',
      label: __('Delete category'),
      icon: 'trash3',
      variant: 'danger',
      separatorTop: true,
      show: () => props.policy.destroy,
      onClick: () =>
        confirmCategoryDelete({
          id: props.id,
          title: props.title,
          isDeletable: props.isDeletable,
        }),
    },
  ]
})
</script>

<template>
  <li :id="listItemId" class="relative">
    <component
      :is="link ? 'CommonLink' : 'div'"
      :link="link"
      :internal="link ? true : undefined"
      class="relative flex size-full flex-col rounded-xl! bg-blue-200 px-3 pt-6 pb-2.25 hover:outline-1 hover:outline-blue-600 dark:bg-gray-500 hover:dark:outline-blue-900"
      :class="[
        {
          'cursor-grab active:cursor-grabbing': isRearranging,
          '-outline-offset-1! outline-blue-900! group-focus-visible:outline': isFocused,
          'outline -outline-offset-1! outline-blue-800!': isSelected,
        },
      ]"
    >
      <CommonIcon
        v-if="isRearranging"
        name="grip-vertical"
        size="small"
        decorative
        class="absolute inset-s-3 top-3 fill-stone-200 dark:fill-neutral-500"
      />
      <!-- Steps aside for the drag handle, which takes the corner it normally sits in. -->
      <CommonBadge
        v-if="translationMissing"
        v-tooltip="$t('No translation available for this locale')"
        variant="warning"
        size="xs"
        rounded
        class="absolute top-3 flex aspect-square items-center justify-center p-1!"
        :class="isRearranging ? 'inset-s-9' : 'inset-s-3'"
      >
        <CommonIcon name="translate" size="xs" decorative />
      </CommonBadge>
      <div class="flex min-h-26.75 flex-col items-center gap-3">
        <KnowledgeBaseIconStatus
          :name="categoryIcon"
          :set="iconSet"
          size="medium"
          :status="visibility"
        />

        <div class="flex min-h-11 w-full items-center justify-center">
          <CommonLabel
            tag="h3"
            size="medium"
            class="line-clamp-2! text-center text-black! dark:text-white!"
          >
            {{ title }}
          </CommonLabel>
        </div>
      </div>

      <CommonDivider v-if="!isSorting" />

      <!-- Counts and menu alike step out while the bar is up: what a category holds says nothing
           about where it belongs in the order. The row itself stays, so the tiles keep their
           height and the grid does not reflow when the bar is armed or dismissed. -->
      <div v-if="!isSorting" class="flex w-full items-center gap-3 pt-2.25">
        <div class="flex items-center gap-1">
          <CommonIcon
            name="folder"
            size="xs"
            decorative
            class="text-stone-200 dark:text-neutral-500"
          />
          <CommonBadge
            v-tooltip="$t('Category count: %s', subcategoryCount)"
            class="cursor-pointer! px-1.5 py-0.5 text-center leading-snug font-bold"
            size="xs"
            rounded
          >
            {{ subcategoryCount }}
          </CommonBadge>
        </div>
        <div class="flex items-center gap-1">
          <CommonIcon
            name="file-richtext"
            size="xs"
            decorative
            class="text-stone-200 dark:text-neutral-500"
          />
          <CommonBadge
            v-tooltip="$t('Answer count: %s', answerCount)"
            class="cursor-pointer! px-1.5 py-0.5 text-center leading-snug font-bold"
            size="xs"
            rounded
          >
            {{ answerCount }}
          </CommonBadge>
        </div>
        <CommonActionMenu
          v-if="actions.length"
          class="ms-auto"
          button-size="small"
          :custom-menu-button-label="$t('Category actions')"
          no-single-action-mode
          :actions="actions"
          placement="arrowEnd"
          @click.prevent
        />
      </div>
    </component>
  </li>
</template>
