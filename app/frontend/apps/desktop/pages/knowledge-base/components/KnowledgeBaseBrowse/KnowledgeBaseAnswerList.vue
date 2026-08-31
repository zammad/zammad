<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useElementVisibility, useInfiniteScroll } from '@vueuse/core'
import { computed, toRef, useTemplateRef, watch, type ComponentPublicInstance } from 'vue'
import { useRouter } from 'vue-router'

import { useDebouncedLoading } from '#shared/composables/useDebouncedLoading.ts'
import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'

import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import { knowledgeBaseAnswerCreateRoute } from '#desktop/entities/knowledge-base/utils/routeLocation.ts'

import { useKnowledgeBaseAnswers } from '../../composables/useKnowledgeBaseAnswers.ts'

import { ADD_CARD_VISIBILITY_THRESHOLD } from './addCardVisibility.ts'
import KnowledgeBaseAddAnswerCard from './KnowledgeBaseAddAnswerCard.vue'
import KnowledgeBaseAnswerCard from './KnowledgeBaseAnswerCard.vue'
import KnowledgeBaseAnswerCardSkeleton from './KnowledgeBaseAnswerCardSkeleton.vue'
import KnowledgeBaseAnswerListSkeleton from './KnowledgeBaseAnswerListSkeleton.vue'

const props = defineProps<{
  // The open category; without one (the knowledge base root) there are no answers.
  categoryId?: string
  // The browsed locale, forwarded from the page (the URL route prop).
  locale?: string
  // The layout's scroll container (it also scrolls the category grid); it drives
  //   the infinite scroll.
  contentContainerElement?: HTMLElement | null
  // Whether the open category takes new answers, from its own `policy.createAnswer` — never the
  //   global editor permission: granular permissions routinely make someone editor of one subtree
  //   and reader elsewhere, so that would offer a button the mutation refuses.
  canAddAnswer?: boolean
  // Whether the answers listed here may be edited, from the open category's `policy.updateAnswer`
  //   - one flag for every row, see KnowledgeBaseAnswerCard's own `canEdit`.
  canEditAnswer?: boolean
}>()

const router = useRouter()

// Reported upwards so the page's floating toolbar can drop its own add-answer shortcut while the
//   real card is on screen - the same thing the category grid does with its add card.
const addAnswerCardVisible = defineModel<boolean>('addAnswerCardVisible')

const addAnswerCardElement = useTemplateRef<ComponentPublicInstance>('add-answer-card')

// Immediate, because the page keys this list by the category and the locale it shows: a switch
//   remounts it, and until this reports the state of its own card the page still holds the one of
//   the previous list. A card that is out of view in both leaves that flag stale at `true`, which
//   costs the toolbar its add-answer shortcut for as long as the card stays off screen.
watch(
  useElementVisibility(addAnswerCardElement, { threshold: ADD_CARD_VISIBILITY_THRESHOLD }),
  (visible) => {
    addAnswerCardVisible.value = visible
  },
  { immediate: true },
)

const { answers, pagination, loading, totalAnswerCount } = useKnowledgeBaseAnswers({
  categoryId: toRef(props, 'categoryId'),
  locale: toRef(props, 'locale'),
})

useInfiniteScroll(
  () => props.contentContainerElement,
  () => pagination.fetchNextPage(),
  {
    distance: 100,
    canLoadMore: () => pagination.hasNextPage,
  },
)

const { debouncedLoading } = useDebouncedLoading({
  isLoading: computed(() => pagination.loadingNewPage ?? false),
})

// Only inside a category: an answer always belongs to one, so there is nothing to add at the
//   knowledge base root.
const showAddAnswer = computed(() => Boolean(props.categoryId) && Boolean(props.canAddAnswer))

// The internal id is what the create form's category field works with (the form updater reads it
//   back to preselect the category), and the route builder mints the draft's tab id.
const addAnswer = () => {
  if (!props.locale || !props.categoryId) return

  router.push(knowledgeBaseAnswerCreateRoute(props.locale, getIdFromGraphQLId(props.categoryId)))
}

defineExpose({ addAnswer })
</script>

<template>
  <CommonLoader :loading="loading">
    <ol class="mt-4 flex flex-col gap-4">
      <KnowledgeBaseAnswerCard
        v-for="answer in answers"
        :key="answer.id"
        v-bind="answer"
        :can-edit="canEditAnswer"
      />
      <!-- Also shown without answers: the only way to create the first one in a category. -->
      <KnowledgeBaseAddAnswerCard v-if="showAddAnswer" ref="add-answer-card" @add="addAnswer" />
      <template v-if="debouncedLoading">
        <KnowledgeBaseAnswerCardSkeleton v-for="i in 3" :key="i" :index="i" />
      </template>
    </ol>

    <template #skeleton>
      <KnowledgeBaseAnswerListSkeleton :count="totalAnswerCount" :with-add-answer="showAddAnswer" />
    </template>
  </CommonLoader>
</template>
