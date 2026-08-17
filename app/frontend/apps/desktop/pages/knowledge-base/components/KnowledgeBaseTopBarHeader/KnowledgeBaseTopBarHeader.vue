<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { isEqual } from 'lodash-es'
import { storeToRefs } from 'pinia'
import { computed } from 'vue'
import { useRouter } from 'vue-router'

import { usePage } from '#desktop/composables/usePage.ts'
import { knowledgeBaseBrowseRoute } from '#desktop/entities/knowledge-base/utils/routeLocation.ts'
import TopBarHeaderCompact from '#desktop/pages/knowledge-base/components/KnowledgeBaseTopBarHeader/TopBarHeaderCompact.vue'
import TopBarHeaderFull from '#desktop/pages/knowledge-base/components/KnowledgeBaseTopBarHeader/TopBarHeaderFull.vue'
import TopBarHeaderFullSkeleton from '#desktop/pages/knowledge-base/components/KnowledgeBaseTopBarHeader/TopBarHeaderFullSkeleton.vue'
import TopBarHeaderShell from '#desktop/pages/knowledge-base/components/KnowledgeBaseTopBarHeader/TopBarHeaderShell.vue'

import { useKnowledgeBaseAccess } from '../../../../entities/knowledge-base/composables/useKnowledgeBaseAccess.ts'
import { useKnowledgeBaseStore } from '../../../../entities/knowledge-base/stores/knowledgeBase.ts'
import { knowledgeBasePreviewUrl } from '../../composables/useKnowledgeBasePreviewUrl.ts'
import { knowledgeBaseBreadcrumbItems } from '../../utils/knowledgeBaseBreadcrumbItems.ts'

import { useKnowledgeBaseHeaderLocales } from './useKnowledgeBaseHeaderLocales.ts'

import type { TopBarHeaderProps } from './types.ts'
import type { CategoryBreadcrumb } from '../../types.ts'

type Props = {
  contentContainerElement: HTMLElement | null
  categoryBreadcrumb?: CategoryBreadcrumb
  // Whether the opened category shows public content in the current locale, so
  //   the header can offer its public-site link while browsing that category.
  categoryVisiblePublicly?: boolean
  // Whether the opened category has no own translation in the browsed locale, so
  //   the header can dock a warning alert below itself (full and compact alike).
  categoryTranslationMissing?: boolean
  // The page's content-loading state (a fresh, uncached category load), so the
  //   header can skeleton in lockstep instead of flashing a stale title.
  loading?: boolean
}

const props = defineProps<Props>()

const router = useRouter()

const { activeLocale, knowledgeBase, loading: baseLoading } = storeToRefs(useKnowledgeBaseStore())

// Skeleton on the initial base load and again on a fresh (uncached) category
//   load, so the header never flashes a stale title before the new breadcrumb
//   resolves.
const loading = computed(() => baseLoading.value || Boolean(props.loading))

const title = computed(
  () =>
    props.categoryBreadcrumb?.at(-1)?.title ?? knowledgeBase.value?.title ?? __('Knowledge Base'),
)

const { canEdit, canRead } = useKnowledgeBaseAccess()

// Deep-link the "view public knowledge base" button to what is being browsed:
//   the opened category, or the base root. The link is only for internal users
//   (reader/editor) — never public visitors — and is offered when that node
//   shows public content in the current locale, or the user is an editor (who
//   can preview unpublished content); undefined otherwise hides the button.
const previewUrl = computed(() => {
  const locale = activeLocale.value
  if (!locale || !canRead.value) return undefined

  const openedCategory = props.categoryBreadcrumb?.at(-1)

  if (openedCategory) {
    if (!props.categoryVisiblePublicly && !canEdit.value) return undefined
    return knowledgeBasePreviewUrl('KnowledgeBaseCategory', openedCategory.id, locale)
  }

  const base = knowledgeBase.value
  if (!base || (!base.isVisiblePublicly && !canEdit.value)) return undefined
  return knowledgeBasePreviewUrl('KnowledgeBase', base.id, locale)
})

const metaTitle = computed(() => {
  const categoryTitle = props.categoryBreadcrumb?.at(-1)?.title

  const kbTitle = knowledgeBase.value?.title ?? __('Knowledge Base')

  return categoryTitle ? `${kbTitle} - ${categoryTitle}` : kbTitle
})

usePage({
  metaTitle,
})

const breadcrumbItems = computed(() =>
  knowledgeBaseBreadcrumbItems({
    localeCode: activeLocale.value,
    categoryBreadcrumb: props.categoryBreadcrumb,
  }),
)

const { localeItems, selectedLocaleItem, selectedLocaleCode } = useKnowledgeBaseHeaderLocales(
  // Stay in the open category when there is one, otherwise land on the
  //   localized root.
  (localeCode) =>
    router.push(knowledgeBaseBrowseRoute(localeCode, props.categoryBreadcrumb?.at(-1)?.id)),
)

const headerProps = computed<TopBarHeaderProps>((currentProps) => {
  const updatedProps = {
    title: title.value,
    locales: localeItems.value,
    breadcrumbs: breadcrumbItems.value,
    localeCode: selectedLocaleCode.value,
    previewUrl: previewUrl.value,
  }

  if (currentProps && isEqual(currentProps, updatedProps)) return currentProps

  return updatedProps
})
</script>

<template>
  <TopBarHeaderShell
    :content-container-element="contentContainerElement"
    :loading="loading"
    :alert-message="
      categoryTranslationMissing ? $t('No translation for this locale available') : undefined
    "
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
