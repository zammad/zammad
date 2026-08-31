<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { isEqual } from 'lodash-es'
import { storeToRefs } from 'pinia'
import { computed } from 'vue'
import { useRouter } from 'vue-router'

import type { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { useKnowledgeBaseStore } from '#desktop/entities/knowledge-base/stores/knowledgeBase.ts'
import { knowledgeBaseAnswerCreateRoute } from '#desktop/entities/knowledge-base/utils/routeLocation.ts'

import { useKnowledgeBaseCategorySubcategories } from '../../composables/useKnowledgeBaseCategorySubcategories.ts'
import { knowledgeBaseBreadcrumbItems } from '../../utils/knowledgeBaseBreadcrumbItems.ts'
import KnowledgeBaseAnswerHeaderDetails from '../KnowledgeBaseTopBarHeader/KnowledgeBaseAnswerHeaderDetails.vue'
import TopBarHeaderCompact from '../KnowledgeBaseTopBarHeader/TopBarHeaderCompact.vue'
import TopBarHeaderFull from '../KnowledgeBaseTopBarHeader/TopBarHeaderFull.vue'
import TopBarHeaderShell from '../KnowledgeBaseTopBarHeader/TopBarHeaderShell.vue'
import { useKnowledgeBaseHeaderLocales } from '../KnowledgeBaseTopBarHeader/useKnowledgeBaseHeaderLocales.ts'

import type { CategoryBreadcrumb } from '../../types.ts'
import type { TopBarHeaderProps } from '../KnowledgeBaseTopBarHeader/types.ts'

// The header of the create view. Deliberately not KnowledgeBaseTopBarHeader: everything that one
//   offers acts on a stored node - the copy button on its title, the public link on its published
//   content, the action menu on the record - and none of that exists while the answer is a draft.
//
// There is no big title row either (see TopBarHeaderFull's titleFieldTarget). The breadcrumb
//   carries the whole heading here, and follows the form as it is filled in: the path of the
//   picked category, then the title being typed. Nothing is stored yet that it could read
//   instead - which is exactly where KnowledgeBaseAnswerEditHeader differs, and reads its
//   heading from the stored answer rather than from what is being typed.
interface Props {
  contentContainerElement: HTMLElement | null
  // Internal id of the category the draft goes into - from the form field once it is set, from
  //   the route otherwise. Also carried over when the locale is switched, so the choice is not
  //   lost with the draft.
  categoryId?: string
  // The title being typed, which is the draft's heading.
  title?: string
  // Where the form's title field (useAnswerFormSchema.ts) teleports its input - see
  //   TopBarHeaderFull's own titleFieldTarget prop for why this container has to be a bare id
  //   rather than a CSS selector.
  titleFieldTarget: string
  // The visibility being picked, live: a draft has no stored answer for the badge row to read
  //   instead, unlike the edit header's.
  visibility?: EnumKnowledgeBaseVisibility
}

const props = defineProps<Props>()

const router = useRouter()

const { activeLocale, loading: baseLoading } = storeToRefs(useKnowledgeBaseStore())

// Switching the language does not retitle this draft - one draft is one translation. It opens
//   another create tab in the selected locale instead, per the story's UX decision.
//
// Unconditionally a create tab, because nothing is stored yet: there is no answer whose
//   translation in the selected locale could be opened for editing instead. On a *saved* answer the
//   edit header does exactly that (KnowledgeBaseAnswerEditHeader.vue), one tab per answer and
//   locale - see Taskbar.entity_key and KnowledgeBase::Answer#taskbar_entities.
const { localeItems, selectedLocaleItem, selectedLocaleCode } = useKnowledgeBaseHeaderLocales(
  (localeCode) => router.push(knowledgeBaseAnswerCreateRoute(localeCode, props.categoryId)),
)

const categoryId = computed(() =>
  props.categoryId ? convertToGraphQLId('KnowledgeBase::Category', props.categoryId) : undefined,
)

// Reuses the browse view's query: opening the create view from a category means its breadcrumb
//   is already in the cache, so the path renders at once instead of after a round trip.
const { breadcrumb } = useKnowledgeBaseCategorySubcategories({
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

// Skeletoned *in place* (`TopBarHeaderProps.loading`), never swapped for
//   TopBarHeaderFullSkeleton - the same rule KnowledgeBaseAnswerEditHeader follows, for the same
//   reason: this header carries the form's title field (`titleFieldTarget` below), and a Teleport
//   resolves its target once, on mount. Unmounting the header to put a skeleton in its place
//   therefore costs the title field for the life of that form, with no way to type one.
//
// Only the knowledge base itself is waited for, never the category's path: `displayedBreadcrumb`
//   above already keeps the previous path on screen while the next one loads, and a category
//   picked in the form must not blank the breadcrumb for the length of its round trip.
const loading = computed(() => baseLoading.value)

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
    loading: loading.value,
  }

  if (currentProps && isEqual(currentProps, updatedProps)) return currentProps

  return updatedProps
})
</script>

<template>
  <TopBarHeaderShell :content-container-element="contentContainerElement" no-title>
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
        :title-field-target="titleFieldTarget"
        :inert="inert"
        content-width="form"
      >
        <template v-if="visibility" #details>
          <KnowledgeBaseAnswerHeaderDetails :answer="{ visibility }" />
        </template>
      </TopBarHeaderFull>
    </template>
  </TopBarHeaderShell>
</template>
