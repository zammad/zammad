<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef, watch, nextTick, onMounted } from 'vue'

import { useArticleToggleMore } from '#shared/composables/useArticleToggleMore.ts'
import { useHtmlInlineImages } from '#shared/composables/useHtmlInlineImages.ts'
import { useHtmlLinks } from '#shared/composables/useHtmlLinks.ts'
import { type ImageViewerFile } from '#shared/composables/useImageViewer.ts'
import type { TicketArticle } from '#shared/entities/ticket/types.ts'
import { textToHtml } from '#shared/utils/helpers.ts'

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

const { shownMore, bubbleElement, hasShowMore, toggleShowMore } =
  useArticleToggleMore()

const bodyClasses = computed(() =>
  props.position === 'right'
    ? ['dark:bg-stone-500', 'bg-blue-100', 'Content--customer']
    : ['dark:bg-gray-400', 'bg-white', 'Content--agent'],
)

const body = computed(() => {
  if (props.article.contentType !== 'text/html') {
    return textToHtml(props.article.bodyWithUrls)
  }
  return props.article.bodyWithUrls
})

const showAuthorInformation = computed(() => {
  const author = props.article.author.fullname // `-` => system message
  return (
    !props.showMetaInformation && author !== '-' && (author?.length ?? 0) > 0
  )
})

const { setupLinksHandlers } = useHtmlLinks('/desktop')
const { populateInlineImages } = useHtmlInlineImages(
  toRef(props, 'inlineImages'),
  (index) => emit('preview', props.inlineImages[index]),
)

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
  <div
    class="Content relative p-3 transition-[padding]"
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
      class="absolute top-3 flex w-full px-3 ltr:left-0 rtl:right-0"
      role="group"
      aria-describedby="author-name-and-creation-date"
    >
      <p id="author-name-and-creation-date" class="sr-only">
        {{ $t('Author name and article creation date') }}
      </p>

      <CommonLabel class="font-bold" size="small" variant="neutral">
        {{ article.author.fullname }}
      </CommonLabel>

      <CommonDateTime
        class="text-xs ltr:ml-auto rtl:mr-auto"
        :date-time="article.createdAt"
      />
    </div>

    <div
      ref="bubbleElement"
      data-test-id="article-content"
      class="overflow-hidden text-sm"
    >
      <!--    eslint-disable vue/no-v-html-->
      <div class="inner-article-body" v-html="body" />
    </div>
    <div
      v-if="hasShowMore"
      class="relative"
      :class="{
        BubbleGradient: hasShowMore && !shownMore,
      }"
    />
    <CommonLink
      v-if="hasShowMore"
      class="mb-1 inline-block! outline-transparent! hover:no-underline! focus-visible:outline-blue-800!"
      role="button"
      link="#"
      size="medium"
      @click.prevent="toggleShowMore"
      @keydown.enter.prevent="toggleShowMore"
    >
      {{ shownMore ? $t('See less') : $t('See more') }}
    </CommonLink>
  </div>
</template>

<style scoped>
.inner-article-body {
  word-break: normal;
  overflow-wrap: anywhere;

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

  /* Wrap long lines in code blocks. */
  &:deep(code) {
    white-space: pre-wrap;
  }

  /* Strip inline color styles in dark mode. */
  [data-theme='dark'] &:deep(*[style*='color']) {
    color: inherit !important;
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
