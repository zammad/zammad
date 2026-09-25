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
import { isTranslationMissing } from '#desktop/entities/knowledge-base/utils/translationLocale.ts'
import KnowledgeBaseAnswerHeaderDetails from '#desktop/pages/knowledge-base/components/KnowledgeBaseTopBarHeader/KnowledgeBaseAnswerHeaderDetails.vue'
import KnowledgeBaseAnswerStepper from '#desktop/pages/knowledge-base/components/KnowledgeBaseTopBarHeader/KnowledgeBaseAnswerStepper.vue'
import TopBarHeaderCompact from '#desktop/pages/knowledge-base/components/KnowledgeBaseTopBarHeader/TopBarHeaderCompact.vue'
import TopBarHeaderFull from '#desktop/pages/knowledge-base/components/KnowledgeBaseTopBarHeader/TopBarHeaderFull.vue'
import TopBarHeaderFullSkeleton from '#desktop/pages/knowledge-base/components/KnowledgeBaseTopBarHeader/TopBarHeaderFullSkeleton.vue'
import TopBarHeaderShell from '#desktop/pages/knowledge-base/components/KnowledgeBaseTopBarHeader/TopBarHeaderShell.vue'

import { knowledgeBasePreviewUrl } from '../../composables/useKnowledgeBasePreviewUrl.ts'
import { knowledgeBaseBreadcrumbItems } from '../../utils/knowledgeBaseBreadcrumbItems.ts'

import { useKnowledgeBaseHeaderLocales } from './useKnowledgeBaseHeaderLocales.ts'

import type { TopBarHeaderProps } from './types.ts'
import type { KnowledgeBaseAnswerCachedHeader, KnowledgeBaseAnswerHeader } from '../../types.ts'

type Props = {
  contentContainerElement: HTMLElement | null
  answer?: KnowledgeBaseAnswerHeader
  // Everything this header shows, read out of the cache while the answer is still on its way -
  //   see useKnowledgeBaseAnswer. Absent for an answer nothing has listed yet.
  cachedHeader?: KnowledgeBaseAnswerCachedHeader
  // Whether the header itself has nothing to show yet, so it can skeleton in lockstep with the
  //   page. Not the page's own loading state: with `cachedHeader` in hand this header is ready
  //   before the answer is.
  loading?: boolean
}

const props = defineProps<Props>()

const router = useRouter()

const { activeLocale, knowledgeBase, loading: baseLoading } = storeToRefs(useKnowledgeBaseStore())

const loading = computed(() => baseLoading.value || Boolean(props.loading))

const { canEdit, canRead } = useKnowledgeBaseAccess()

// The answer as the header renders it: the loaded record once it is there, the cached pre-info
//   until then. The two carry the same three things this header shows, so everything below reads
//   one of them without caring which - and none of it changes when the answer lands, which is the
//   whole point (the details row is the exception, see `#details` in the template).
const headerContent = computed(() => {
  const { answer, cachedHeader } = props

  if (!answer) return cachedHeader

  return {
    id: answer.id,
    translation: answer.translation,
    visibility: answer.visibility,
    breadcrumb: answer.category?.breadcrumb,
  }
})

// The "view public knowledge base" button deep-links to the opened answer. It is
//   only for internal users (reader/editor) — never public visitors — and is
//   offered when the answer is published, or the user is an editor (who can
//   preview unpublished content); undefined otherwise hides the button.
const previewUrl = computed(() => {
  const locale = activeLocale.value
  const content = headerContent.value

  if (!locale || !content || !canRead.value) return undefined
  if (content.visibility !== EnumKnowledgeBaseVisibility.Published && !canEdit.value)
    return undefined

  return knowledgeBasePreviewUrl('KnowledgeBaseAnswer', content.id, locale)
})

// No action menu here: the answer's actions live in the sidebar's header, beside the section title
//   (see KnowledgeBaseAnswer.vue). This header keeps what acts on the *page* - the breadcrumb, the
//   locale, the title copy and the public preview link.

// The answer as this locale has it: its title, and whether that title is this locale's own or the
//   fallback served for one that has none.
const translation = computed(() => headerContent.value?.translation)

const translationMissing = computed(
  () => Boolean(headerContent.value) && isTranslationMissing(translation.value, activeLocale.value),
)

// From the loaded answer only: the stepper describes the answer's place in its category's listing,
//   which is not something a cached entry written by that listing can say - and it sits in the
//   controls row, so arriving with the answer costs the header no height.
const stepperNavigation = computed(() => props.answer?.translation?.navigation)

const metaTitle = computed(() => {
  const kbTitle = knowledgeBase.value?.translation?.title ?? __('Knowledge Base')

  return translation.value?.title ? `${kbTitle} - ${translation.value.title}` : kbTitle
})

usePage({
  metaTitle,
})

const breadcrumbItems = computed(() =>
  knowledgeBaseBreadcrumbItems({
    localeCode: activeLocale.value,
    categoryBreadcrumb: headerContent.value?.breadcrumb,
    trailingItem: headerContent.value
      ? { label: translation.value?.title ?? '', noOptionLabelTranslation: true }
      : undefined,
  }),
)

const { localeItems, selectedLocaleItem, selectedLocaleCode } = useKnowledgeBaseHeaderLocales(
  // The answer is the same record in every locale, so switching languages stays
  //   on it instead of falling back to the category listing.
  (localeCode) => {
    const content = headerContent.value

    if (!content) return

    router.push(knowledgeBaseAnswerRoute(localeCode, content.id))
  },
)

const headerProps = computed<TopBarHeaderProps>((currentProps) => {
  const updatedProps = {
    title: translation.value?.title,
    locales: localeItems.value,
    breadcrumbs: breadcrumbItems.value,
    localeCode: selectedLocaleCode.value,
    previewUrl: previewUrl.value,
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
    :alert-message="translationMissing ? $t('No translation available for this locale') : undefined"
    content-width="reading"
  >
    <template #compact="{ inert }">
      <TopBarHeaderCompact
        v-model:selected-locale="selectedLocaleItem"
        v-bind="headerProps"
        :copy-label="__('Copy answer title')"
        :inert="inert"
      >
        <template v-if="stepperNavigation && activeLocale" #stepper>
          <KnowledgeBaseAnswerStepper :navigation="stepperNavigation" :locale-code="activeLocale" />
        </template>
      </TopBarHeaderCompact>
    </template>

    <template #full="{ inert }">
      <!-- The details row is the one thing the cached pre-info cannot fill, so it says for itself
           that it is still loading - otherwise it would be absent until the answer lands and the
           header would grow a row on arrival. -->
      <TopBarHeaderFull
        v-model:selected-locale="selectedLocaleItem"
        v-bind="headerProps"
        :copy-label="__('Copy answer title')"
        :inert="inert"
        :loading-details="!answer"
        content-width="reading"
      >
        <template v-if="stepperNavigation && activeLocale" #stepper>
          <KnowledgeBaseAnswerStepper :navigation="stepperNavigation" :locale-code="activeLocale" />
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
