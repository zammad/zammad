<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { isEqual } from 'lodash-es'
import { storeToRefs } from 'pinia'
import { computed, ref, watch } from 'vue'
import { useRouter } from 'vue-router'

import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { useKnowledgeBaseStore } from '#desktop/entities/knowledge-base/stores/knowledgeBase.ts'
import { knowledgeBaseAnswerCreateRoute } from '#desktop/entities/knowledge-base/utils/routeLocation.ts'

import { useKnowledgeBaseCategorySubcategories } from '../../composables/useKnowledgeBaseCategorySubcategories.ts'
import { knowledgeBaseBreadcrumbItems } from '../../utils/knowledgeBaseBreadcrumbItems.ts'
import TopBarHeaderCompact from '../KnowledgeBaseTopBarHeader/TopBarHeaderCompact.vue'
import TopBarHeaderFull from '../KnowledgeBaseTopBarHeader/TopBarHeaderFull.vue'
import TopBarHeaderFullSkeleton from '../KnowledgeBaseTopBarHeader/TopBarHeaderFullSkeleton.vue'
import TopBarHeaderShell from '../KnowledgeBaseTopBarHeader/TopBarHeaderShell.vue'
import { useKnowledgeBaseHeaderLocales } from '../KnowledgeBaseTopBarHeader/useKnowledgeBaseHeaderLocales.ts'

import type { CategoryBreadcrumb } from '../../types.ts'
import type { TopBarHeaderProps } from '../KnowledgeBaseTopBarHeader/types.ts'

// The header of the create view. Deliberately not KnowledgeBaseTopBarHeader: everything that one
//   offers acts on a stored node - the copy button on its title, the public link on its published
//   content, the action menu on the record - and none of that exists while the answer is a draft.
//
// There is no big title row either. The breadcrumb carries the whole heading here, and follows
//   the form as it is filled in: the category path of the selected category, then the title
//   being typed (its last item renders as the page's `h1`).
interface Props {
  contentContainerElement: HTMLElement | null
  // Internal id of the category the draft goes into - from the form field once it is set, from
  //   the route otherwise. Also carried over when the locale is switched, so the choice is not
  //   lost with the draft.
  categoryId?: string
  // The title being typed, which is the draft's heading.
  title?: string
}

const props = defineProps<Props>()

const router = useRouter()

const { activeLocale, loading: baseLoading } = storeToRefs(useKnowledgeBaseStore())

// Switching the language does not retitle this draft - one draft is one translation. It opens
//   another create tab in the selected locale instead, per the story's UX decision.
//
// Unconditionally a create tab, because nothing is stored yet: there is no answer whose
//   translation in the selected locale could be opened for editing instead. That fork belongs to
//   the edit story (zammad/coordination-desktop-view#785), which switches locales on a *saved*
//   answer - and which has to settle whether a tab is one per answer or one per answer and
//   locale before it can be built.
const { localeItems, selectedLocaleItem, selectedLocaleCode } = useKnowledgeBaseHeaderLocales(
  (localeCode) => router.push(knowledgeBaseAnswerCreateRoute(localeCode, props.categoryId)),
)

const categoryId = computed(() =>
  props.categoryId ? convertToGraphQLId('KnowledgeBase::Category', props.categoryId) : undefined,
)

// Reuses the browse view's query: opening the create view from a category means its breadcrumb
//   is already in the cache, so the path renders at once instead of after a round trip.
const { breadcrumb, loading: categoryLoading } = useKnowledgeBaseCategorySubcategories({
  categoryId,
  locale: activeLocale,
})

// The category path, kept on screen while the next one loads. Here the selected category is a
//   form field, and picking one the editor never browsed means a round trip: unlike the browse
//   view - which opens a category from its parent's listing, where its path came along and is in
//   the cache - there is nothing cached to bridge that gap, the form's options being plain
//   values. Blanking the path meanwhile would make the heading jump twice per switch.
const displayedBreadcrumb = computed<CategoryBreadcrumb>((previous) => {
  if (!categoryId.value) return []

  return breadcrumb.value.length ? breadcrumb.value : (previous ?? [])
})

// Only skeleton for a category whose path is not known yet - not while it is being refreshed
//   under a breadcrumb that is already on screen.
const initialLoading = computed(
  () =>
    baseLoading.value ||
    (categoryLoading.value && Boolean(categoryId.value) && !displayedBreadcrumb.value.length),
)

// The skeleton belongs to the initial load, where the header comes up together with the form
//   below it. Once it is up it stays: from then on the category comes from a field the editor
//   changes, and replacing the whole header for the length of its round trip reads as the top
//   bar flashing away - nothing else on the page changes on such a switch either.
const headerShown = ref(false)

watch(
  initialLoading,
  (loading) => {
    if (!loading) headerShown.value = true
  },
  { immediate: true },
)

const loading = computed(() => initialLoading.value && !headerShown.value)

const breadcrumbs = computed(() =>
  knowledgeBaseBreadcrumbItems({
    localeCode: activeLocale.value,
    categoryBreadcrumb: displayedBreadcrumb.value,
    trailingItem: {
      label: props.title || (__('New knowledge base answer') as string),
      // A typed title is user content; only the fallback is UI copy.
      noOptionLabelTranslation: Boolean(props.title),
    },
  }),
)

const headerProps = computed<TopBarHeaderProps>((currentProps) => {
  const updatedProps = {
    locales: localeItems.value,
    breadcrumbs: breadcrumbs.value,
    localeCode: selectedLocaleCode.value,
    noCopyButton: true,
  }

  if (currentProps && isEqual(currentProps, updatedProps)) return currentProps

  return updatedProps
})
</script>

<template>
  <TopBarHeaderShell
    :content-container-element="contentContainerElement"
    :loading="loading"
    no-title
  >
    <template #compact="{ inert }">
      <TopBarHeaderCompact
        v-model:selected-locale="selectedLocaleItem"
        v-bind="headerProps"
        :inert="inert"
      />
    </template>

    <template #full="{ inert }">
      <TopBarHeaderFull
        v-model:selected-locale="selectedLocaleItem"
        v-bind="headerProps"
        :inert="inert"
      />
    </template>

    <template #skeleton>
      <TopBarHeaderFullSkeleton />
    </template>
  </TopBarHeaderShell>
</template>
