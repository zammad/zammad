<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef, watch, nextTick, onMounted } from 'vue'

import { useArticleToggleMore } from '#shared/composables/useArticleToggleMore.ts'
import { useHtmlInlineImages } from '#shared/composables/useHtmlInlineImages.ts'
import { useHtmlLinks } from '#shared/composables/useHtmlLinks.ts'
import { type ImageViewerFile } from '#shared/composables/useImageViewer.ts'
import type { TicketArticle } from '#shared/entities/ticket/types.ts'
import { i18n } from '#shared/i18n.ts'
import { textToHtml, ensureImagesKeepAspectRatio } from '#shared/utils/helpers.ts'

import { useAnnouncer } from '#desktop/composables/accessibility/useAnnouncer.ts'

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

const { shownMore, bubbleElement, hasShowMore, toggleShowMore } = useArticleToggleMore()

const bodyClasses = computed(() =>
  props.position === 'right'
    ? ['dark:bg-stone-500', 'bg-blue-100', 'Content--customer']
    : ['dark:bg-gray-400', 'bg-white', 'Content--agent'],
)

const body = computed(() => {
  if (props.article.bodyRenderingError) {
    return textToHtml(i18n.t(props.article.bodyWithUrls))
  }
  if (props.article.contentType !== 'text/html') {
    return textToHtml(props.article.bodyWithUrls)
  }
  return ensureImagesKeepAspectRatio(props.article.bodyWithUrls)
})

const showAuthorInformation = computed(() => {
  const author = props.article.author.fullname // `-` => system message

  return !props.showMetaInformation && author !== '-' && (author?.length ?? 0) > 0
})

const { setupLinksHandlers } = useHtmlLinks('/desktop')
const { populateInlineImages } = useHtmlInlineImages(toRef(props, 'inlineImages'), (index) =>
  emit('preview', props.inlineImages[index]),
)

useArticleHighlights(
  bubbleElement,
  computed(() => props.article.highlightedTexts ?? undefined),
  body,
)

const { descriptionId, description } = useArticleHighlightsA11y(
  bubbleElement,
  computed(() => props.article.highlightedTexts ?? undefined),
  body,
  computed(() => props.article.internalId),
)

const { announce } = useAnnouncer()

useArticleHighlightsSelection(
  bubbleElement,
  computed(() => props.article.highlightedTexts ?? undefined),
  computed(() => props.article.id),
  announce,
)

const toggleShowMoreAndEmit = () => {
  toggleShowMore()
}

watch(
  () => body,
  async () => {
    await nextTick()
    if (bubbleElement.value) {
      setupLinksHandlers(bubbleElement.value)
      populateInlineImages(bubbleElement.value)
    }
  },
)

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
      class="absolute top-3 flex w-full px-3 ltr:left-0 rtl:right-0 print:hidden"
      aria-describedby="author-name-and-creation-date"
    >
      <p id="author-name-and-creation-date" class="sr-only">
        {{ $t('Author name and article creation date') }}
      </p>

      <CommonLabel class="line-clamp-1! font-bold" size="small" variant="neutral">
        {{ article.author.fullname }}
      </CommonLabel>

      <CommonDateTime
        class="shrink-0 text-xs ltr:ml-auto rtl:mr-auto"
        :date-time="article.createdAt"
      />
    </div>

    <div
      ref="bubbleElement"
      data-test-id="article-content"
      class="overflow-hidden text-sm transition-[height] duration-200 print:h-auto! print:overflow-visible"
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
    <CommonLink
      v-if="hasShowMore"
      class="mb-1 inline-block! outline-transparent! hover:underline! focus-visible:outline-blue-800! print:hidden!"
      role="button"
      link="#"
      size="medium"
      @click.prevent="toggleShowMoreAndEmit"
      @keydown.enter.prevent="toggleShowMoreAndEmit"
    >
      {{ shownMore ? $t('See less') : $t('See more') }}
    </CommonLink>
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
