<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed } from 'vue'
import { useRouter } from 'vue-router'

import CommonBadge from '#shared/components/CommonBadge/CommonBadge.vue'
import CommonIcon from '#shared/components/CommonIcon/CommonIcon.vue'
import CommonLabel from '#shared/components/CommonLabel/CommonLabel.vue'

import CommonActionMenu from '#desktop/components/CommonActionMenu/CommonActionMenu.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import KnowledgeBaseAnswerIcon from '#desktop/components/KnowledgeBaseAnswerIcon/KnowledgeBaseAnswerIcon.vue'
import { useKnowledgeBaseAnswerDelete } from '#desktop/entities/knowledge-base/composables/useKnowledgeBaseAnswerDelete.ts'
import { useKnowledgeBaseStore } from '#desktop/entities/knowledge-base/stores/knowledgeBase.ts'
import {
  knowledgeBaseAnswerEditRoute,
  knowledgeBaseAnswerRoute,
} from '#desktop/entities/knowledge-base/utils/routeLocation.ts'

import type { KnowledgeBaseAnswerCompact } from '../../types.ts'

const props = defineProps<
  KnowledgeBaseAnswerCompact & {
    // From the *category* this card is listed under, not from the answer: KnowledgeBase::
    //   AnswerPolicy#update? resolves the access of the answer's category, so every answer here
    //   gives the same result - and a per-answer policy would ask the same question once per row
    //   (KnowledgeBase::CategoryPolicy#update_answer?).
    canEdit?: boolean
    // Likewise from the category, via its `policy.destroyAnswer`.
    canDelete?: boolean
    // The category this card is listed under, for the delete's cache scope - see the action below.
    categoryId?: string
    // Whether the sorting bar is up, in any of its modes. The card is then a row in a listing
    //   being arranged and nothing else: no menu and no link — see below.
    isSorting?: boolean
    // Whether this listing is the one being dragged, i.e. `isSorting` in the manual mode. Only
    //   that mode gives the card a grip and a drag cursor; the automatic ones arrange it
    //   themselves.
    isRearranging?: boolean
    // DOM id of the list item, which `aria-activedescendant` on the list points at while it is
    //   navigated by keyboard. Spelled out rather than let through as a fallthrough attribute:
    //   `id` is a prop here (the answer's), so an `id` attribute would overwrite it.
    listItemId?: string
  }
>()

const router = useRouter()

const { activeLocale } = storeToRefs(useKnowledgeBaseStore())

// The answer route pins the locale; without it there is no valid target yet. While the sorting
//   bar is up there is deliberately no target at all: opening an answer from underneath it would
//   abandon a mode or an order the editor has not saved yet — a picked mode counts as much as a
//   drag — so the card falls back to its plain `div`.
const link = computed(() =>
  activeLocale.value && !props.isSorting
    ? knowledgeBaseAnswerRoute(activeLocale.value, props.id)
    : undefined,
)

const { confirmAnswerDelete } = useKnowledgeBaseAnswerDelete()

const actions = computed<MenuItem[]>(() => {
  const localeCode = activeLocale.value

  // Not while the bar is up, like the category card's own menu: the card is then a row in a
  //   listing being arranged, and every entry here leads away from the unsaved order.
  if (props.isSorting) return []

  const items: MenuItem[] = []

  // Editing continues in the browsed locale, like the reader's own edit action - the edit route
  //   carries one, and its taskbar tab is per answer *and* locale.
  if (props.canEdit && localeCode) {
    items.push({
      key: 'edit-answer',
      label: __('Edit answer'),
      icon: 'pencil',
      onClick: () => router.push(knowledgeBaseAnswerEditRoute(localeCode, props.id)),
    })
  }

  if (props.canDelete) {
    items.push({
      key: 'delete-answer',
      label: __('Delete answer'),
      icon: 'trash3',
      variant: 'danger',
      separatorTop: true,
      // The category is handed over for the cache scope, not to navigate: a card is never the
      //   answer being read, so this page stays. It is what lowers the count of a *cached* listing
      //   of this same category - another locale's - whose loaded window never held this answer.
      onClick: () =>
        confirmAnswerDelete({ id: props.id, title: props.title }, { categoryId: props.categoryId }),
    })
  }

  return items
})
</script>

<template>
  <li :id="listItemId">
    <component
      :is="link ? 'CommonLink' : 'div'"
      :link="link"
      :internal="link ? true : undefined"
      class="flex h-12.5 w-full items-center gap-2 rounded-xl! bg-blue-200 px-3 hover:outline-1 hover:outline-blue-600 dark:bg-gray-500 hover:dark:outline-blue-900"
      :class="{ 'cursor-grab active:cursor-grabbing': isRearranging }"
    >
      <CommonIcon
        v-if="isRearranging"
        name="grip-vertical"
        size="small"
        decorative
        class="shrink-0 fill-stone-200 dark:fill-neutral-500"
      />

      <KnowledgeBaseAnswerIcon :visibility="visibility" size="tiny" />

      <CommonLabel size="medium" tag="h3" class="line-clamp-1! grow text-black! dark:text-white!">
        {{ title }}
      </CommonLabel>

      <CommonBadge
        v-if="translationMissing"
        v-tooltip="$t('No translation available for this locale')"
        variant="warning"
        size="xs"
        rounded
        class="flex items-center justify-center p-1!"
      >
        <CommonIcon name="translate" size="xs" decorative />
      </CommonBadge>

      <!-- `@click.prevent`, like the category card's own menu: the whole row is the link to the
           answer, and opening the menu must not follow it. -->
      <CommonActionMenu
        v-if="actions.length"
        class="inline-flex! items-center"
        button-size="medium"
        :custom-menu-button-label="$t('Answer actions')"
        no-single-action-mode
        :actions="actions"
        placement="arrowEnd"
        @click.prevent
      />
    </component>
  </li>
</template>
