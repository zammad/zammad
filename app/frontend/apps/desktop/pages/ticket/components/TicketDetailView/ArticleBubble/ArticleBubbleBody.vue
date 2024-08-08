<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef, watch, nextTick, onMounted } from 'vue'

import { useArticleToggleMore } from '#shared/composables/useArticleToggleMore.ts'
import { useHtmlInlineImages } from '#shared/composables/useHtmlInlineImages.ts'
import { useHtmlLinks } from '#shared/composables/useHtmlLinks.ts'
import { type ImageViewerFile } from '#shared/composables/useImageViewer.ts'
import type { TicketArticle } from '#shared/entities/ticket/types.ts'
import { textToHtml } from '#shared/utils/helpers.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

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
    class="Content -:pt-9 -:p-3 relative transition-[padding]"
    :class="[
      bodyClasses,
      {
        'pt-3': showMetaInformation,
      },
    ]"
  >
    <div
      v-if="!showMetaInformation"
      class="absolute top-3 flex w-full px-3 ltr:left-0 rtl:right-0"
    >
      <CommonLabel class="font-bold" size="small" variant="neutral">
        {{
          article.author.fullname ||
          `${article.author.firstname} ${article.author.lastname}`
        }}
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
      <div v-html="body" />
    </div>
    <div
      v-if="hasShowMore"
      class="relative"
      :class="{
        BubbleGradient: hasShowMore && !shownMore,
      }"
    ></div>
    <CommonButton
      v-if="hasShowMore"
      class="!p-0 !outline-transparent"
      size="medium"
      @click.prevent="toggleShowMore"
      @keydown.enter.prevent="toggleShowMore"
    >
      {{ shownMore ? $t('See less') : $t('See more') }}
    </CommonButton>
  </div>
</template>

<style scoped>
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
  background: linear-gradient(rgba(255, 255, 255, 0), theme('colors.white'));
}

[data-theme='dark'] .Content--agent .BubbleGradient::before {
  background: linear-gradient(rgba(255, 255, 255, 0), theme('colors.gray.400'));
}

.Content--customer .BubbleGradient::before {
  background: linear-gradient(rgba(255, 255, 255, 0), theme('colors.blue.100'));
}

[data-theme='dark'] .Content--customer .BubbleGradient::before {
  background: linear-gradient(
    rgba(255, 255, 255, 0),
    theme('colors.stone.500')
  );
}
</style>
