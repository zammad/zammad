<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, defineAsyncComponent, ref } from 'vue'

import { useAttachments } from '#shared/composables/useAttachments.ts'
import type { TicketArticle } from '#shared/entities/ticket/types.ts'
import { EnumTicketArticleSenderName } from '#shared/graphql/types.ts'

import UserPopoverWithTrigger from '#desktop/components/User/UserPopoverWithTrigger.vue'
import { useFilePreviewViewer, type ViewerFile } from '#desktop/composables/useFilePreviewViewer.ts'
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
    import('#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/ArticleBubbleHeader.vue'),
)

interface Props {
  article: TicketArticle
}

const props = defineProps<Props>()

const { showMetaInformation, toggleHeader } = useBubbleHeader()

const toggleHeaderFromKeyboard = () => {
  toggleHeader(new MouseEvent('click'))
}

const metaInformationRegionId = computed(
  () => `article-meta-information-${props.article.internalId}`,
)

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
  () => (props.article.type?.name === 'note' && props.article.internal) || props.article.internal,
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
    class="group/article relative rounded-t-xl backface-hidden"
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
    <UserPopoverWithTrigger
      class="absolute! bottom-0"
      :class="{
        'ltr:-right-2.5 ltr:translate-x-full rtl:-left-2.5 rtl:-translate-x-full':
          position === 'right',
        'ltr:-left-2.5 ltr:-translate-x-full rtl:-right-2.5 rtl:translate-x-full':
          position === 'left',
      }"
      :user="article.author"
      :popover-config="{
        placement: 'arrowStart',
      }"
      :avatar-config="{
        size: 'small',
        noIndicator: true,
      }"
      z-index="52"
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
        :id="metaInformationRegionId"
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
        :class="[headerAndIconBarBackgroundClass, showMetaInformation ? dividerClass : '']"
        :article="article"
      />

      <ArticleBubbleSecurityWarning :article="article" />
      <ArticleBubbleMediaError :article="article" />

      <div
        class="relative isolate"
        :class="{
          'nth-2:rounded-t-xl': !showMetaInformation,
          'nth-2:ltr:rounded-br-none nth-2:ltr:rounded-bl-xl nth-2:rtl:rounded-br-xl nth-2:rtl:rounded-bl-none':
            position === 'right',
          'nth-2:ltr:rounded-br-xl nth-2:ltr:rounded-bl-none nth-2:rtl:rounded-br-none nth-2:rtl:rounded-bl-xl':
            position === 'left',
        }"
      >
        <button
          type="button"
          class="pointer-events-none absolute top-0 z-10 size-full rounded-[inherit] border-blue-800 focus:outline-none focus-visible:border ltr:left-0 rtl:right-0"
          :aria-label="$t('Toggle article meta information')"
          :aria-expanded="showMetaInformation"
          :aria-controls="metaInformationRegionId"
          @keydown.enter.prevent="toggleHeaderFromKeyboard"
          @keydown.space.prevent="toggleHeaderFromKeyboard"
        />

        <ArticleBubbleBody
          :data-test-id="`article-bubble-body-${article.internalId}`"
          class="z-5 h-full"
          :class="[bodyClasses]"
          :position="position"
          :show-meta-information="showMetaInformation"
          :inline-images="inlineImages"
          :article="article"
          @preview="showPreview('image', $event)"
          @click="toggleHeader"
        />
      </div>

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
