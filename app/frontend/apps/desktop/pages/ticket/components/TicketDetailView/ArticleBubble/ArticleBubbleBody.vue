<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef, watch, nextTick, onMounted, useTemplateRef } from 'vue'

import { useArticleToggleMore } from '#shared/composables/useArticleToggleMore.ts'
import { useHtmlInlineImages } from '#shared/composables/useHtmlInlineImages.ts'
import { useHtmlLinks } from '#shared/composables/useHtmlLinks.ts'
import { type ImageViewerFile } from '#shared/composables/useImageViewer.ts'
import type { TicketArticle } from '#shared/entities/ticket/types.ts'
import { useArticleTranslationStore } from '#shared/entities/ticket-article/stores/articleTranslation.ts'
import { i18n } from '#shared/i18n.ts'
import { textToHtml, ensureImagesKeepAspectRatio } from '#shared/utils/helpers.ts'

import CommonAIFeedback from '#desktop/components/CommonAIFeedback/CommonAIFeedback.vue'
import { useAnnouncer } from '#desktop/composables/accessibility/useAnnouncer.ts'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

import { useArticleHighlights } from './useArticleHighlights/useArticleHighlights.ts'
import { useArticleHighlightsA11y } from './useArticleHighlights/useArticleHighlightsA11y.ts'
import { useArticleHighlightsSelection } from './useArticleHighlights/useArticleHighlightsSelection.ts'

interface Props {
  article: TicketArticle
  showMetaInformation: boolean
  position: 'left' | 'right'
  inlineImages: ImageViewerFile[]
}

const props = defineProps<Props>()

const emit = defineEmits<{
  preview: [image: ImageViewerFile]
}>()

const { shownMore, bubbleElement, hasShowMore, toggleShowMore, recalculateHeight } =
  useArticleToggleMore()

const { articleTranslation } = useTicketInformation()

const translationStore = useArticleTranslationStore()

const translation = computed(() => articleTranslation.translationFor(props.article.id))

// A finished translation; an empty article gets none and keeps its original.
const displayedTranslation = computed(() =>
  translation.value?.status === 'done' && translation.value.translated ? translation.value : null,
)

const isAiTranslation = computed(() => displayedTranslation.value?.backend === 'ai')

const translationAttribution = computed(() => {
  if (!displayedTranslation.value) return ''

  return isAiTranslation.value
    ? __('Translated by AI, some formatting may be lost.')
    : __('Machine-translated, some formatting may be lost.')
})

const translationAnalytics = computed(() => displayedTranslation.value?.analytics)

const translationFeedback = useTemplateRef('translation-feedback')

const isTranslationFeedbackCommenting = computed(
  () => !!translationFeedback.value?.showCommentField,
)

const translationDirection = computed(() =>
  displayedTranslation.value ? translationStore.targetLocaleData?.dir?.toLowerCase() : undefined,
)

const bodyClasses = computed(() =>
  props.position === 'right'
    ? ['dark:bg-stone-500', 'bg-blue-100', 'Content--customer']
    : ['dark:bg-gray-400', 'bg-white', 'Content--agent'],
)

const body = computed(() => {
  // The translation comes in the format of the original, so it takes the same path.
  const content = displayedTranslation.value?.content ?? props.article.bodyWithUrls

  if (props.article.bodyRenderingError && !displayedTranslation.value) {
    return textToHtml(i18n.t(content))
  }
  if (props.article.contentType !== 'text/html') {
    return textToHtml(content)
  }
  return ensureImagesKeepAspectRatio(content)
})

// Highlights are offsets into the original text and mean nothing in a translation.
const highlightedTexts = computed(() =>
  displayedTranslation.value ? undefined : (props.article.highlightedTexts ?? undefined),
)

const showAuthorInformation = computed(() => {
  const author = props.article.author.fullname // `-` => system message

  return !props.showMetaInformation && author !== '-' && (author?.length ?? 0) > 0
})

const { setupLinksHandlers } = useHtmlLinks('/desktop')
const { populateInlineImages } = useHtmlInlineImages(toRef(props, 'inlineImages'), (index) =>
  emit('preview', props.inlineImages[index]),
)

useArticleHighlights(bubbleElement, highlightedTexts, body)

const { descriptionId, description } = useArticleHighlightsA11y(
  bubbleElement,
  highlightedTexts,
  body,
  computed(() => props.article.internalId),
)

const { announce } = useAnnouncer()

useArticleHighlightsSelection(
  bubbleElement,
  highlightedTexts,
  computed(() => props.article.id),
  announce,
  computed(() => !displayedTranslation.value),
)

const toggleShowMoreAndEmit = () => {
  toggleShowMore()
}

// A swapped body brings its own links and images, and a different height to collapse to.
watch(body, async () => {
  // Pinned at its current height until measured, so a longer body never shows at full size first.
  //   Without the transition: it would otherwise animate down from the new content's full height.
  // Not in a hidden tab: detached from the document, the element has no height to pin.
  const element = bubbleElement.value
  if (element?.isConnected && !element.style.height) {
    element.style.transitionProperty = 'none'
    element.style.height = `${element.clientHeight}px`
  }

  await nextTick()
  if (element) {
    void element.offsetHeight // applies the pin before the transition is back
    element.style.transitionProperty = ''
  }
  if (bubbleElement.value) {
    setupLinksHandlers(bubbleElement.value)
    populateInlineImages(bubbleElement.value)
    recalculateHeight()
  }
})

onMounted(() => {
  if (bubbleElement.value) {
    setupLinksHandlers(bubbleElement.value)
    populateInlineImages(bubbleElement.value)
  }
})
</script>

<template>
  <article
    class="Content relative overflow-hidden p-3 pb-4 transition-[padding] print:pt-3!"
    :class="[
      bodyClasses,
      {
        'pt-3!': showMetaInformation,
        'pt-9!': showAuthorInformation,
      },
    ]"
  >
    <div
      v-if="showAuthorInformation"
      class="absolute inset-s-0 top-3 flex w-full px-3 print:hidden"
      aria-describedby="author-name-and-creation-date"
    >
      <p id="author-name-and-creation-date" class="sr-only">
        {{ $t('Author name and article creation date') }}
      </p>

      <CommonLabel class="line-clamp-1! font-bold" size="small" variant="neutral">
        {{ article.author.fullname }}
      </CommonLabel>

      <CommonDateTime class="ms-auto shrink-0 text-xs" :date-time="article.createdAt" />
    </div>

    <div
      ref="bubbleElement"
      data-test-id="article-content"
      class="overflow-hidden text-sm transition-[height] duration-200 print:h-auto! print:overflow-visible"
      :dir="translationDirection"
    >
      <!--    Never drop this inner-article-body class used for Highlight feature-->
      <!--    eslint-disable vue/no-v-html-->
      <section class="inner-article-body" :aria-details="descriptionId" v-html="body" />

      <div v-if="descriptionId" :id="descriptionId" class="sr-only">
        {{ description }}
      </div>
    </div>
    <div
      v-if="hasShowMore"
      class="relative print:hidden"
      :class="{
        BubbleGradient: !shownMore,
      }"
    />
    <div
      v-if="hasShowMore || displayedTranslation"
      class="flex flex-wrap items-center gap-x-2.5 gap-y-1 py-1 print:hidden"
      data-test-id="article-body-toolbar"
    >
      <CommonLink
        v-if="hasShowMore"
        class="inline-block! outline-transparent! hover:underline! focus-visible:outline-blue-800!"
        role="button"
        link="#"
        size="medium"
        @click.prevent="toggleShowMoreAndEmit"
        @keydown.enter.prevent="toggleShowMoreAndEmit"
      >
        {{ shownMore ? $t('See less') : $t('See more') }}
      </CommonLink>

      <CommonLabel
        v-if="displayedTranslation"
        class="ms-auto text-stone-200! dark:text-neutral-500!"
        size="xs"
        tag="p"
        prefix-icon="translate"
        data-test-id="article-translation-attribution"
      >
        {{ $t(translationAttribution) }}
      </CommonLabel>

      <CommonAIFeedback
        v-if="translationAnalytics?.run?.id"
        ref="translation-feedback"
        :class="{ 'w-full': isTranslationFeedbackCommenting }"
        :analytics-meta="translationAnalytics"
        no-usage-tracking
        regenerate-variant="neutral"
        data-test-id="article-translation-feedback"
        :no-ai-based="!isAiTranslation"
        :regenerating="displayedTranslation?.regenerating"
        @rated="articleTranslation.markTranslationRated(article.id)"
        @regenerate="articleTranslation.regenerateTranslation(article.id)"
      >
        <template #success>
          <CommonLabel class="-ms-2 flex! text-stone-200! dark:text-neutral-500!" size="xs">
            {{ $t('Thank you for your feedback.') }}
          </CommonLabel>
        </template>
      </CommonAIFeedback>
    </div>
  </article>
</template>

<style scoped>
.inner-article-body {
  word-break: normal;
  overflow-wrap: anywhere;
  overflow-x: auto;

  /*
   * TODO: Consider extending this rule to other elements.
   *
   * Relevant elements include:
   * - img, svg, canvas, audio, iframe, embed, object
   *
   * These elements inherit a `display: block` style from the root stylesheet.
   */

  &:deep(img, svg) {
    display: inline;
  }

  /*
    `overflow-wrap: anywhere` above lets long unbroken text (e.g. URLs)
    break instead of stretching the bubble. But that also lets table
    columns collapse toward zero width, since the browser's table layout
    treats a breakable word as having almost no minimum width. This starves
    narrow columns in favor of wide ones instead of letting the table
    overflow and scroll (via `overflow-x: auto` above) at a readable width.
    Reset to `normal` scoped to tables so columns keep their natural width.
  */
  &:deep(table) {
    overflow-wrap: normal;
  }

  /*
    Strip inline background styles in dark mode (e.g. tables pasted from
    external emails), so the bubble's own dark background shows through
    instead of clashing with a light-mode background left over from the
    original HTML.
  */
  [data-theme='dark'] &:deep(*[style*='background']) {
    background: transparent !important;
  }
}

.BubbleGradient::before {
  content: '';
  position: absolute;
  left: 0;
  right: 0;
  bottom: 0;
  height: 46px;
  pointer-events: none;
}

.Content--agent .BubbleGradient::before {
  background: linear-gradient(rgba(255, 255, 255, 0), var(--color-white));
}

[data-theme='dark'] .Content--agent .BubbleGradient::before {
  background: linear-gradient(rgba(255, 255, 255, 0), var(--color-gray-400));
}

.Content--customer .BubbleGradient::before {
  background: linear-gradient(rgba(255, 255, 255, 0), var(--color-blue-100));
}

[data-theme='dark'] .Content--customer .BubbleGradient::before {
  background: linear-gradient(rgba(255, 255, 255, 0), var(--color-stone-500));
}
</style>
