<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { isEqual } from 'lodash-es'
import { storeToRefs } from 'pinia'
import { computed } from 'vue'
import { useRouter } from 'vue-router'

import { useKnowledgeBaseStore } from '#desktop/entities/knowledge-base/stores/knowledgeBase.ts'
import { knowledgeBaseAnswerEditRoute } from '#desktop/entities/knowledge-base/utils/routeLocation.ts'

import { knowledgeBaseBreadcrumbItems } from '../../utils/knowledgeBaseBreadcrumbItems.ts'
import KnowledgeBaseAnswerHeaderDetails from '../KnowledgeBaseTopBarHeader/KnowledgeBaseAnswerHeaderDetails.vue'
import TopBarHeaderCompact from '../KnowledgeBaseTopBarHeader/TopBarHeaderCompact.vue'
import TopBarHeaderFull from '../KnowledgeBaseTopBarHeader/TopBarHeaderFull.vue'
import TopBarHeaderShell from '../KnowledgeBaseTopBarHeader/TopBarHeaderShell.vue'
import { useKnowledgeBaseHeaderLocales } from '../KnowledgeBaseTopBarHeader/useKnowledgeBaseHeaderLocales.ts'

import type { KnowledgeBaseAnswerHeader } from '../../types.ts'
import type { TopBarHeaderProps } from '../KnowledgeBaseTopBarHeader/types.ts'

// The header of the edit view: the create header's shape (no big title row, see
//   TopBarHeaderFull's titleFieldTarget) plus the badge row it has nothing to show yet, but
//   neither the reader's stepper nor its public preview link: stepping to the neighbouring answer
//   from a tab that holds unsaved work is not something to offer, and a preview would open the
//   stored answer rather than the work in the form. Not KnowledgeBaseAnswerTopBarHeader
//   (the reader's): that one renders a big title row, which the story's UX decision replaces with
//   the title field for as long as it lives in the header (provisional, see the plan) - so this
//   stays its own component rather than a variant of it.
//
// The breadcrumb and the badges both come from the *stored* answer only, never from the form: a
//   typed but unsaved title, category or visibility reaches the heading once it is saved and not
//   before. Unlike the create header, which has no stored answer to read instead and so follows
//   the form. That is also why this header needs nothing from the form beyond the title field
//   itself, teleported straight in.
interface Props {
  contentContainerElement: HTMLElement | null
  // The stored answer, for everything here that acts on a persisted record - undefined only for
  //   the instant before its query has resolved.
  answer?: KnowledgeBaseAnswerHeader
  // Where the form's title field (useAnswerFormSchema.ts) teleports its input - see
  //   TopBarHeaderFull's own titleFieldTarget prop for why this container has to be a bare id
  //   rather than a CSS selector.
  titleFieldTarget: string
  // Whether this locale has no translation of its own, decided by the view for its own tab rather
  //   than read off the active locale here: a tab in the background outlives being looked at, and
  //   the active locale is then the one of whichever tab is open.
  translationMissing?: boolean
}

const props = defineProps<Props>()

const router = useRouter()

const { activeLocale } = storeToRefs(useKnowledgeBaseStore())

// Everything the header shows is fed from the stored answer, so its rows skeleton until the
//   answer is there - the reader's header does the same, and without this one rendered a
//   breadcrumb holding nothing but the knowledge base root and replaced it a moment later.
//
// Skeletoned *in place* rather than swapped for TopBarHeaderFullSkeleton the way the reader's
//   header is: the shell unmounts the full header to skeleton it, and the form's title field is
//   teleported in here (`titleFieldTarget` below) with its target resolved once, on mount. Since
//   `CommonLoader` swaps through a `Transition` with `mode="out-in"`, the replacement header
//   arrives a frame *after* the form that teleports into it - so the field would never find its
//   container and the title could not be edited at all.
//
// Not gated on the knowledge base store either (`useKnowledgeBaseStore().loading`): the route
//   guard awaits it before this view is created (useKnowledgeBaseLocaleGuard), so it is settled
//   by the time anything here renders.
const loading = computed(() => !props.answer)

// One tab is one translation, so switching the language here opens the edit tab of that other
//   translation rather than retitling this one.
const { localeItems, selectedLocaleItem, selectedLocaleCode } = useKnowledgeBaseHeaderLocales(
  (localeCode) => {
    if (!props.answer) return

    router.push(knowledgeBaseAnswerEditRoute(localeCode, props.answer.id))
  },
)

// The whole heading - category path and title alike - comes from the stored answer, not the form:
//   a typed but unsaved category move or rename only takes effect once the save round trip lands
//   and refetches the answer. Exactly the reader header's own breadcrumb, for the same reason.
const breadcrumbs = computed(() =>
  knowledgeBaseBreadcrumbItems({
    localeCode: activeLocale.value,
    categoryBreadcrumb: props.answer?.category?.breadcrumb,
    trailingItem: props.answer
      ? { label: props.answer.translation?.title ?? '', noOptionLabelTranslation: true }
      : undefined,
  }),
)

const headerProps = computed<TopBarHeaderProps>((currentProps) => {
  const updatedProps = {
    locales: localeItems.value,
    breadcrumbs: breadcrumbs.value,
    localeCode: selectedLocaleCode.value,
    // Nothing rendered as the header's own title (the field carries it, and the breadcrumb above
    //   reads the stored one instead of it), so there is nothing for the copy button to copy.
    noCopyButton: true,
    loading: loading.value,
  }

  if (currentProps && isEqual(currentProps, updatedProps)) return currentProps

  return updatedProps
})
</script>

<template>
  <TopBarHeaderShell
    :content-container-element="contentContainerElement"
    :alert-message="translationMissing ? $t('No translation available for this locale') : undefined"
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
        :title-field-target="titleFieldTarget"
        :inert="inert"
        content-width="form"
      >
        <template v-if="answer" #details>
          <KnowledgeBaseAnswerHeaderDetails :answer="answer" />
        </template>
      </TopBarHeaderFull>
    </template>
  </TopBarHeaderShell>
</template>
