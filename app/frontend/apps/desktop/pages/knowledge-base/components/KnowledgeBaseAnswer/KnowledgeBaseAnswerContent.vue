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

  /*
    Strip inline color styles in dark mode.
      However, we need to keep the colors of the Zammad palette.
  */
  [data-theme='dark'] &:deep(*[style*='color']):not(
    [style*='color:rgb(102, 102, 102)'], [style*='color: rgb(102, 102, 102)'], /* neutral 1 */
    [style*='color:rgb(153, 153, 153)'], [style*='color: rgb(153, 153, 153)'], /* neutral 2 */
    [style*='color:rgb(204, 204, 204)'], [style*='color: rgb(204, 204, 204)'], /* neutral 3 */

    [style*='color:rgb(239, 68, 68)'], [style*='color: rgb(239, 68, 68)'], /* red 1 */
    [style*='color:rgb(205, 121, 45)'], [style*='color: rgb(205, 121, 45)'], /* orange 1 */
    [style*='color:rgb(80, 140, 70)'], [style*='color: rgb(80, 140, 70)'], /* green 1 */
    [style*='color:rgb(48, 100, 172)'], [style*='color: rgb(48, 100, 172)'], /* blue 1 */
    [style*='color:rgb(107, 41, 132)'], [style*='color: rgb(107, 41, 132)'], /* purple 1 */

    [style*='color:rgb(235, 61, 79)'], [style*='color: rgb(235, 61, 79)'], /* red 2 */
    [style*='color:rgb(233, 159, 59)'], [style*='color: rgb(233, 159, 59)'], /* orange 2 */
    [style*='color:rgb(95, 159, 84)'], [style*='color: rgb(95, 159, 84)'], /* green 2 */
    [style*='color:rgb(70, 147, 231)'], [style*='color: rgb(70, 147, 231)'], /* blue 2 */
    [style*='color:rgb(153, 62, 195)'], [style*='color: rgb(153, 62, 195)'], /* purple 2 */

    [style*='color:rgb(237, 97, 118)'], [style*='color: rgb(237, 97, 118)'], /* red 3 */
    [style*='color:rgb(243, 193, 79)'], [style*='color: rgb(243, 193, 79)'], /* orange 3 */
    [style*='color:rgb(127, 187, 118)'], [style*='color: rgb(127, 187, 118)'], /* green 3 */
    [style*='color:rgb(91, 174, 243)'], [style*='color: rgb(91, 174, 243)'], /* blue 3 */
    [style*='color:rgb(179, 91, 223)'], [style*='color: rgb(179, 91, 223)'], /* purple 3 */

    [style*='color:rgb(241, 152, 167)'], [style*='color: rgb(241, 152, 167)'], /* red 4 */
    [style*='color:rgb(246, 211, 102)'], [style*='color: rgb(246, 211, 102)'], /* orange 4 */
    [style*='color:rgb(170, 214, 164)'], [style*='color: rgb(170, 214, 164)'], /* green 4 */
    [style*='color:rgb(122, 202, 247)'], [style*='color: rgb(122, 202, 247)'], /* blue 4 */
    [style*='color:rgb(201, 135, 236)'], [style*='color: rgb(201, 135, 236)'] /* purple 4 */
  ) {
    color: inherit !important;
  }
}
</style>
