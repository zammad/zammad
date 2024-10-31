<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, defineAsyncComponent, ref } from 'vue'

import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import { useAttachments } from '#shared/composables/useAttachments.ts'
import type { TicketArticle } from '#shared/entities/ticket/types.ts'
import { EnumTicketArticleSenderName } from '#shared/graphql/types.ts'

import {
  useFilePreviewViewer,
  type ViewerFile,
} from '#desktop/composables/useFilePreviewViewer.ts'
import ArticleBubbleActionList from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/ArticleBubbleActionList.vue'
import ArticleBubbleBlockedContentWarning from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/ArticleBubbleBlockedContentWarning.vue'
import ArticleBubbleBody from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/ArticleBubbleBody.vue'
import ArticleBubbleFooter from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/ArticleBubbleFooter.vue'
import ArticleBubbleMediaError from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/ArticleBubbleMediaError.vue'
import ArticleBubbleSecurityStatusBar from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/ArticleBubbleSecurityStatusBar.vue'
import ArticleBubbleSecurityWarning from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/ArticleBubbleSecurityWarning.vue'
import { useBubbleHeader } from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/useBubbleHeader.ts'
import { useBubbleStyleGuide } from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/useBubbleStyleGuide.ts'
import ArticleReactionBadge from '#desktop/pages/ticket/components/TicketDetailView/ArticleReactionBadge.vue'

const ArticleBubbleHeader = defineAsyncComponent(
  () =>
    import(
      '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/ArticleBubbleHeader.vue'
    ),
)

interface Props {
  article: TicketArticle
}

const props = defineProps<Props>()

const { showMetaInformation, toggleHeader } = useBubbleHeader()

const position = computed(() => {
  switch (props.article.sender?.name) {
    case EnumTicketArticleSenderName.Customer:
      return 'right'
    case EnumTicketArticleSenderName.System:
      return 'left'
    case EnumTicketArticleSenderName.Agent:
      return 'left'
    default:
      return 'left'
  }
})

const hasInternalNote = computed(
  () =>
    (props.article.type?.name === 'note' && props.article.internal) ||
    props.article.internal,
)

const {
  frameBorderClass,
  dividerClass,
  bodyClasses,
  headerAndIconBarBackgroundClass,
  articleWrapperBorderClass,
  internalNoteClass,
} = useBubbleStyleGuide(position, hasInternalNote)

const filteredAttachments = computed(() => {
  return props.article.attachmentsWithoutInline.filter(
    (file) => !file.preferences || !file.preferences['original-format'],
  )
})

const { attachments: articleAttachments } = useAttachments({
  attachments: filteredAttachments,
})

const inlineImages = ref<ViewerFile[]>([])

const { showPreview } = useFilePreviewViewer(
  computed(() => [...inlineImages.value, ...articleAttachments.value]),
)
</script>

<template>
  <div
    class="group/article backface-hidden relative rounded-t-xl"
    :data-test-id="`article-bubble-container-${article.internalId}`"
    :class="[
      {
        'ltr:rounded-bl-xl rtl:rounded-br-xl': position === 'right',
        'ltr:rounded-br-xl rtl:rounded-bl-xl': position === 'left',
      },
      frameBorderClass,
      internalNoteClass,
    ]"
  >
    <CommonUserAvatar
      class="!absolute bottom-0"
      :class="{
        'ltr:-right-2.5 ltr:translate-x-full rtl:-left-2.5 rtl:-translate-x-full':
          position === 'right',
        'ltr:-left-2.5 ltr:-translate-x-full rtl:-right-2.5 rtl:translate-x-full':
          position === 'left',
      }"
      :entity="article.author"
      size="small"
      no-indicator
    />

    <div
      class="grid w-full grid-rows-[0fr] overflow-hidden rounded-xl transition-[grid-template-rows]"
      :class="[
        {
          'grid-rows-[1fr]': showMetaInformation,
        },
        articleWrapperBorderClass,
      ]"
    >
      <div
        :aria-hidden="!showMetaInformation"
        class="grid w-full grid-rows-[0fr] overflow-hidden"
      >
        <Transition name="pseudo-transition">
          <ArticleBubbleHeader
            v-if="showMetaInformation"
            :aria-label="$t('Article meta information')"
            :class="headerAndIconBarBackgroundClass"
            :show-meta-information="showMetaInformation"
            :position="position"
            :article="article"
          />
        </Transition>
      </div>

      <ArticleBubbleSecurityStatusBar
        v-if="!showMetaInformation"
        :class="[
          headerAndIconBarBackgroundClass,
          showMetaInformation ? dividerClass : '',
        ]"
        :article="article"
      />

      <ArticleBubbleSecurityWarning :article="article" />
      <ArticleBubbleMediaError :article="article" />

      <ArticleBubbleBody
        tabindex="0"
        :data-test-id="`article-bubble-body-${article.internalId}`"
        class="last:rounded-b-xl focus:outline-none focus-visible:-outline-offset-2 focus-visible:outline-blue-800"
        :class="[
          bodyClasses,
          {
            'pt-3': showMetaInformation,
            '[&:nth-child(2)]:rounded-t-xl': !showMetaInformation,
            'rtl:rounded-br-none [&:nth-child(2)]:ltr:rounded-br-none':
              position === 'right',
            'rtl:rounded-br-none [&:nth-child(2)]:ltr:rounded-bl-none':
              position === 'left',
          },
        ]"
        :position="position"
        :show-meta-information="showMetaInformation"
        :inline-images="inlineImages"
        :article="article"
        @click="toggleHeader"
        @keydown.enter="toggleHeader"
        @preview="showPreview('image', $event)"
      />

      <ArticleBubbleBlockedContentWarning
        :class="[
          dividerClass,
          bodyClasses,
          {
            'pt-3': showMetaInformation,
          },
        ]"
        :article="article"
      />

      <ArticleBubbleFooter
        :article="article"
        :article-attachments="articleAttachments"
        @preview="showPreview"
      />
    </div>

    <ArticleBubbleActionList :article="article" :position="position" />

    <ArticleReactionBadge
      :position="position"
      :reaction="article.preferences?.whatsapp?.reaction?.emoji"
    />
  </div>
</template>
