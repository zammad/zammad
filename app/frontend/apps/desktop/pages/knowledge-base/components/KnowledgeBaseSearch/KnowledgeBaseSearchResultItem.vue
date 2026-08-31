<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import CommonLabel from '#shared/components/CommonLabel/CommonLabel.vue'

import CommonHighlightedText from '#desktop/components/CommonHighlightedText/CommonHighlightedText.vue'
import KnowledgeBaseAnswerIcon from '#desktop/components/KnowledgeBaseAnswerIcon/KnowledgeBaseAnswerIcon.vue'
import { useKnowledgeBaseStore } from '#desktop/entities/knowledge-base/stores/knowledgeBase.ts'
import { knowledgeBaseBrowseRoute } from '#desktop/entities/knowledge-base/utils/routeLocation.ts'

import { knowledgeBaseSearchResultRoute } from '../../utils/knowledgeBaseSearchReturn.ts'
import KnowledgeBaseIconStatus from '../KnowledgeBaseIconStatus.vue'

import KnowledgeBaseSearchResultCategoryPath from './KnowledgeBaseSearchResultCategoryPath.vue'

import type { KnowledgeBaseSearchResult } from '../../types.ts'

const props = defineProps<{
  result: KnowledgeBaseSearchResult
  query: string
  categoryId?: string
}>()

const activeLocale = toRef(useKnowledgeBaseStore(), 'activeLocale')

// The hit is either an answer or a category; the two need different icons and routes.
const answer = computed(() =>
  props.result.item.__typename === 'KnowledgeBaseAnswer' ? props.result.item : undefined,
)
const category = computed(() =>
  props.result.item.__typename === 'KnowledgeBaseCategory' ? props.result.item : undefined,
)

// Both routes pin the locale; without it there is no valid target yet.
const link = computed(() => {
  if (!activeLocale.value) return undefined

  return answer.value
    ? knowledgeBaseSearchResultRoute(activeLocale.value, answer.value.id, {
        term: props.query,
        categoryId: props.categoryId,
      })
    : // Category hit doesn't need the search term
      knowledgeBaseBrowseRoute(activeLocale.value, props.result.item.id)
})

// A title always matched somewhere or the hit would not exist, but the preview may still be
//   empty (e.g. a body-only match answered by the SQL fallback) — then show the plain title.
const titleSegments = computed(() =>
  props.result.titlePreview.length
    ? props.result.titlePreview
    : // Read off the narrowed hit: the category's title is aliased in the query, since it and an
      //   answer's differ in nullability and so cannot share one response name.
      [{ text: answer.value?.title ?? category.value?.categoryTitle ?? '', highlight: false }],
)
</script>

<template>
  <li v-if="category">
    <component
      :is="link ? 'CommonLink' : 'div'"
      :link="link"
      :internal="link ? true : undefined"
      class="flex size-full flex-col items-center gap-3 rounded-xl! bg-blue-200 px-3 py-4 hover:outline-1 hover:outline-blue-600 dark:bg-gray-500 hover:dark:outline-blue-900"
    >
      <KnowledgeBaseIconStatus
        :name="category.categoryIcon"
        :set="category.iconSet"
        :status="category.visibility"
        size="medium"
      />

      <CommonLabel size="medium" class="line-clamp-2! text-center text-black! dark:text-white!">
        <CommonHighlightedText :segments="titleSegments" />
      </CommonLabel>

      <KnowledgeBaseSearchResultCategoryPath
        :category-path="result.categoryPath"
        class="w-full justify-center"
      />
    </component>
  </li>

  <li v-else>
    <component
      :is="link ? 'CommonLink' : 'div'"
      :link="link"
      :internal="link ? true : undefined"
      class="flex w-full items-start gap-3 rounded-xl! bg-blue-200 px-3 py-2.5 hover:outline-1 hover:outline-blue-600 dark:bg-gray-500 hover:dark:outline-blue-900"
    >
      <KnowledgeBaseAnswerIcon
        v-if="answer"
        :visibility="answer.visibility"
        size="small"
        class="mt-0.5"
      />

      <div class="flex min-w-0 grow flex-col gap-0.5">
        <CommonLabel size="medium" class="line-clamp-1! text-black! dark:text-white!">
          <CommonHighlightedText :segments="titleSegments" />
        </CommonLabel>

        <CommonLabel
          v-if="answer && result.bodyPreview.length"
          tag="p"
          size="medium"
          class="line-clamp-2!"
        >
          <CommonHighlightedText :segments="result.bodyPreview" />
        </CommonLabel>

        <KnowledgeBaseSearchResultCategoryPath :category-path="result.categoryPath" />
      </div>
    </component>
  </li>
</template>
