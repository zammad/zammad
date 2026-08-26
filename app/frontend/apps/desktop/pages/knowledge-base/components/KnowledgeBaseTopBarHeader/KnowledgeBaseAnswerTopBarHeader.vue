<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { isEqual } from 'lodash-es'
import { storeToRefs } from 'pinia'
import { computed } from 'vue'
import { useRouter } from 'vue-router'

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'

import { usePage } from '#desktop/composables/usePage.ts'
import { useKnowledgeBaseAccess } from '#desktop/entities/knowledge-base/composables/useKnowledgeBaseAccess.ts'
import { useKnowledgeBaseStore } from '#desktop/entities/knowledge-base/stores/knowledgeBase.ts'
import {
  knowledgeBaseAnswerRoute,
  knowledgeBaseBrowseRoute,
} from '#desktop/entities/knowledge-base/utils/routeLocation.ts'
import KnowledgeBaseAnswerHeaderDetails from '#desktop/pages/knowledge-base/components/KnowledgeBaseTopBarHeader/KnowledgeBaseAnswerHeaderDetails.vue'
import KnowledgeBaseAnswerStepper from '#desktop/pages/knowledge-base/components/KnowledgeBaseTopBarHeader/KnowledgeBaseAnswerStepper.vue'
import TopBarHeaderCompact from '#desktop/pages/knowledge-base/components/KnowledgeBaseTopBarHeader/TopBarHeaderCompact.vue'
import TopBarHeaderFull from '#desktop/pages/knowledge-base/components/KnowledgeBaseTopBarHeader/TopBarHeaderFull.vue'
import TopBarHeaderFullSkeleton from '#desktop/pages/knowledge-base/components/KnowledgeBaseTopBarHeader/TopBarHeaderFullSkeleton.vue'
import TopBarHeaderShell from '#desktop/pages/knowledge-base/components/KnowledgeBaseTopBarHeader/TopBarHeaderShell.vue'

import { useKnowledgeBaseFeedAction } from '../../composables/useKnowledgeBaseFeedAction.ts'
import { knowledgeBasePreviewUrl } from '../../composables/useKnowledgeBasePreviewUrl.ts'
import { knowledgeBaseBreadcrumbItems } from '../../utils/knowledgeBaseBreadcrumbItems.ts'

import { useKnowledgeBaseHeaderLocales } from './useKnowledgeBaseHeaderLocales.ts'

import type { TopBarHeaderProps } from './types.ts'
import type { KnowledgeBaseAnswerHeader } from '../../types.ts'

type Props = {
  contentContainerElement: HTMLElement | null
  answer?: KnowledgeBaseAnswerHeader
  // The page's answer-loading state, so the header can skeleton in lockstep.
  loading?: boolean
}

const props = defineProps<Props>()

const router = useRouter()

const { activeLocale, knowledgeBase, loading: baseLoading } = storeToRefs(useKnowledgeBaseStore())

const loading = computed(() => baseLoading.value || Boolean(props.loading))

const { canEdit, canRead } = useKnowledgeBaseAccess()

// The "view public knowledge base" button deep-links to the opened answer. It is
//   only for internal users (reader/editor) — never public visitors — and is
//   offered when the answer is published, or the user is an editor (who can
//   preview unpublished content); undefined otherwise hides the button.
const previewUrl = computed(() => {
  const locale = activeLocale.value
  const { answer } = props

  if (!locale || !answer || !canRead.value) return undefined
  if (answer.visibility !== EnumKnowledgeBaseVisibility.Published && !canEdit.value)
    return undefined

  return knowledgeBasePreviewUrl('KnowledgeBaseAnswer', answer.id, locale)
})

// The answer's own category, so its feed is offered like in the old interface.
const { feedActions } = useKnowledgeBaseFeedAction(computed(() => props.answer?.category?.id))

const metaTitle = computed(() => {
  const kbTitle = knowledgeBase.value?.title ?? __('Knowledge Base')

  return props.answer?.title ? `${kbTitle} - ${props.answer.title}` : kbTitle
})

usePage({
  metaTitle,
})

const breadcrumbItems = computed(() =>
  knowledgeBaseBreadcrumbItems({
    localeCode: activeLocale.value,
    categoryBreadcrumb: props.answer?.category?.breadcrumb,
    trailingItem: props.answer
      ? { label: props.answer.title ?? '', noOptionLabelTranslation: true }
      : undefined,
  }),
)

const { localeItems, selectedLocaleItem, selectedLocaleCode } = useKnowledgeBaseHeaderLocales(
  // The answer is the same record in every locale, so switching languages stays
  //   on it instead of falling back to the category listing.
  (localeCode) => {
    if (!props.answer) return

    router.push(knowledgeBaseAnswerRoute(localeCode, props.answer.id))
  },
)

const headerProps = computed<TopBarHeaderProps>((currentProps) => {
  const updatedProps = {
    title: props.answer?.title,
    locales: localeItems.value,
    breadcrumbs: breadcrumbItems.value,
    localeCode: selectedLocaleCode.value,
    previewUrl: previewUrl.value,
    actions: feedActions.value,
    // `focus: 'search'` is a one-shot signal the search screen picks up to focus its
    //   input and then strips from the URL - see KnowledgeBaseBrowse.vue.
    searchLink: activeLocale.value
      ? { ...knowledgeBaseBrowseRoute(activeLocale.value), query: { focus: 'search' } }
      : undefined,
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
      answer?.translationMissing ? $t('No translation for this locale available') : undefined
    "
    content-width="reading"
  >
    <template #compact="{ inert }">
      <TopBarHeaderCompact
        v-model:selected-locale="selectedLocaleItem"
        v-bind="headerProps"
        :copy-label="__('Copy answer title')"
        :inert="inert"
      >
        <template v-if="answer?.navigation && activeLocale" #stepper>
          <KnowledgeBaseAnswerStepper :navigation="answer.navigation" :locale-code="activeLocale" />
        </template>
      </TopBarHeaderCompact>
    </template>

    <template #full="{ inert }">
      <TopBarHeaderFull
        v-model:selected-locale="selectedLocaleItem"
        v-bind="headerProps"
        :copy-label="__('Copy answer title')"
        :inert="inert"
        content-width="reading"
      >
        <template v-if="answer?.navigation && activeLocale" #stepper>
          <KnowledgeBaseAnswerStepper :navigation="answer.navigation" :locale-code="activeLocale" />
        </template>

        <template v-if="answer" #details>
          <KnowledgeBaseAnswerHeaderDetails :answer="answer" />
        </template>
      </TopBarHeaderFull>
    </template>

    <template #skeleton>
      <TopBarHeaderFullSkeleton with-details content-width="reading" />
    </template>
  </TopBarHeaderShell>
</template>
