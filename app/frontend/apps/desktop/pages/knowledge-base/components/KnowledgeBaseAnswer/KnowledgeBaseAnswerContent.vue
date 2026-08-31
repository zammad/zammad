<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, nextTick, onMounted, ref, useTemplateRef, watch } from 'vue'

import { useHtmlInlineImages } from '#shared/composables/useHtmlInlineImages.ts'
import { useHtmlLinks } from '#shared/composables/useHtmlLinks.ts'
import { setAutoDirectionOnChildElements } from '#shared/utils/dom.ts'
import { ensureImagesKeepAspectRatio } from '#shared/utils/helpers.ts'

import { useFilePreviewViewer, type ViewerFile } from '#desktop/composables/useFilePreviewViewer.ts'

const props = defineProps<{
  content?: Maybe<{ bodyWithUrls?: Maybe<string> }>
}>()

const bodyElement = useTemplateRef('content-body')

// The body arrives sanitized and prepared from the server (`bodyWithUrls`): inline `cid:`
//   images point at their attachment URL, links to other answers are resolved and video
//   widget markers are expanded into embeds.
const body = computed(() => {
  const bodyWithUrls = props.content?.bodyWithUrls

  if (!bodyWithUrls) return ''

  return ensureImagesKeepAspectRatio(bodyWithUrls)
})

const inlineImages = ref<ViewerFile[]>([])

const { showPreview } = useFilePreviewViewer(inlineImages)

const { setupLinksHandlers } = useHtmlLinks('/desktop')
const { populateInlineImages } = useHtmlInlineImages(inlineImages, (index) =>
  showPreview('image', inlineImages.value[index]),
)

// `v-html` replaces the nodes, so the handlers must be attached again whenever the body
//   changes — on locale switch, on previous/next navigation and on a content update refetch.
const setupBody = async () => {
  await nextTick()

  if (!bodyElement.value) return

  setupLinksHandlers(bodyElement.value)
  populateInlineImages(bodyElement.value)
  setAutoDirectionOnChildElements(bodyElement.value)
}

watch(body, setupBody)

onMounted(setupBody)
</script>

<template>
  <!-- Focusable so the body can be reached by keyboard, and named so that stop is announced —
       which also makes the section a region, as an unnamed one is not. -->
  <section
    v-if="body"
    :aria-label="$t('Answer')"
    class="Content w-full rounded-sm focus-visible-app-default"
  >
    <!-- eslint-disable vue/no-v-html -->
    <article ref="content-body" class="inner-article-body text-sm" v-html="body" />
  </section>
</template>

<style scoped>
.inner-article-body {
  word-break: normal;
  overflow-wrap: anywhere;

  /* A full-page answer reads with more air than a ticket article bubble. */
  &:deep(p) {
    margin-block: 1rem;
  }

  &:deep(img, svg) {
    display: inline;
  }

  /* Video widgets are expanded server-side into this wrapper; keep them responsive 16:9. */
  &:deep(.videoWrapper) {
    position: relative;
    height: 0;
    padding-block: 25px 56.25%;

    iframe {
      position: absolute;
      inset-block-start: 0;
      inset-inline-start: 0;
      width: 100%;
      height: 100%;
    }
  }
}
</style>
