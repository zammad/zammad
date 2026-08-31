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
  }
>()

const router = useRouter()

const { activeLocale } = storeToRefs(useKnowledgeBaseStore())

// The answer route pins the locale; without it there is no valid target yet.
const link = computed(() =>
  activeLocale.value ? knowledgeBaseAnswerRoute(activeLocale.value, props.id) : undefined,
)

// Editing continues in the browsed locale, like the reader's own edit action - the edit route
//   carries one, and its taskbar tab is per answer *and* locale.
const actions = computed<MenuItem[]>(() => {
  const localeCode = activeLocale.value

  if (!props.canEdit || !localeCode) return []

  return [
    {
      key: 'edit-answer',
      label: __('Edit answer'),
      icon: 'pencil',
      onClick: () => router.push(knowledgeBaseAnswerEditRoute(localeCode, props.id)),
    },
  ]
})
</script>

<template>
  <li>
    <component
      :is="link ? 'CommonLink' : 'div'"
      :link="link"
      :internal="link ? true : undefined"
      class="flex h-12.5 w-full items-center gap-3 rounded-xl! bg-blue-200 px-3 hover:outline-1 hover:outline-blue-600 dark:bg-gray-500 hover:dark:outline-blue-900"
    >
      <KnowledgeBaseAnswerIcon :visibility="visibility" size="small" />
      <CommonLabel size="medium" tag="h3" class="line-clamp-1! grow text-black! dark:text-white!">
        {{ title }}
      </CommonLabel>
      <CommonBadge
        v-if="translationMissing"
        v-tooltip="$t('No translation for this locale available')"
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
        button-size="small"
        :custom-menu-button-label="$t('Answer actions')"
        no-single-action-mode
        :actions="actions"
        placement="arrowEnd"
        @click.prevent
      />
    </component>
  </li>
</template>
