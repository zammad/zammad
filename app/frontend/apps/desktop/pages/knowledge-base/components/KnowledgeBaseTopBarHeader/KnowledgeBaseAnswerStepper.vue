<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { isEqual } from 'lodash-es'
import { computed, toRef } from 'vue'

import { i18n } from '#shared/i18n.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'

import { knowledgeBaseAnswerRoute } from '#desktop/entities/knowledge-base/utils/routeLocation.ts'

import type { AnswerNavigationEntry, Navigation } from './types.ts'

export interface Props {
  navigation: Navigation
  localeCode: string
}

const props = defineProps<Props>()

const localeData = toRef(useLocaleStore(), 'localeData')

const previousAnswer = computed<AnswerNavigationEntry>((currentAnswer) => {
  const answer = {
    link: knowledgeBaseAnswerRoute(props.localeCode, props.navigation.previousAnswer.id),
    label: props.navigation.previousAnswer.translation?.title
      ? i18n.t('Previous answer: %s', props.navigation.previousAnswer.translation.title)
      : i18n.t('Previous answer'),
  }

  if (currentAnswer && isEqual(answer, currentAnswer)) return currentAnswer

  return answer
})

const nextAnswer = computed<AnswerNavigationEntry>((currentAnswer) => {
  const answer = {
    link: knowledgeBaseAnswerRoute(props.localeCode, props.navigation.nextAnswer.id),
    label: props.navigation.nextAnswer.translation?.title
      ? i18n.t('Next answer: %s', props.navigation.nextAnswer.translation.title)
      : i18n.t('Next answer'),
  }

  if (currentAnswer && isEqual(answer, currentAnswer)) return currentAnswer

  return answer
})
</script>

<template>
  <nav v-if="navigation.totalCount > 1" :aria-label="$t('Answer navigation')">
    <ol
      class="ms-1 inline-flex items-center gap-0.5 rounded-md border border-neutral-100 bg-green-200 px-1 py-0.5 dark:border-gray-900 dark:bg-gray-600"
    >
      <li>
        <CommonLink v-tooltip="previousAnswer.label" :link="previousAnswer.link">
          <CommonIcon
            size="xs"
            :name="localeData?.dir === 'rtl' ? 'chevron-right' : 'chevron-left'"
          />
        </CommonLink>
      </li>

      <li class="flex px-1 text-stone-200 dark:text-neutral-500">
        <CommonLabel size="small">
          {{ navigation.index }}
        </CommonLabel>

        <CommonLabel class="">/</CommonLabel>

        <CommonLabel size="small">
          {{ navigation.totalCount }}
        </CommonLabel>
      </li>

      <li>
        <CommonLink v-tooltip="nextAnswer.label" :link="nextAnswer.link">
          <CommonIcon
            size="xs"
            :name="localeData?.dir === 'rtl' ? 'chevron-left' : 'chevron-right'"
          />
        </CommonLink>
      </li>
    </ol>
  </nav>
</template>
