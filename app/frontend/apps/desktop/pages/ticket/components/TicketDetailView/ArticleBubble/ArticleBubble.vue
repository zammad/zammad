<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, defineAsyncComponent, ref } from 'vue'

import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import { useArticleAttachments } from '#shared/composables/useArticleAttachments.ts'
import {
  type ImageViewerFile,
  useImageViewer,
} from '#shared/composables/useImageViewer.ts'
import type { TicketArticle } from '#shared/entities/ticket/types.ts'
import { EnumTicketArticleSenderName } from '#shared/graphql/types.ts'

import ArticleBubbleActionList from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/ArticleBubbleActionList.vue'
import ArticleBubbleBlockedContentWarning from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/ArticleBubbleBlockedContentWarning.vue'
import ArticleBubbleBody from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/ArticleBubbleBody.vue'
import ArticleBubbleFooter from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/ArticleBubbleFooter.vue'
import ArticleBubbleSecurityStatusBar from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/ArticleBubbleSecurityStatusBar.vue'
import ArticleBubbleSecurityWarning from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/ArticleBubbleSecurityWarning.vue'
import { useBubbleHeader } from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/useBubbleHeader.ts'
import { useBubbleStyleGuide } from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/useBubbleStyleGuide.ts'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

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

const { ticket } = useTicketInformation()

const { showMetaInformation, toggleHeader } = useBubbleHeader()

const position = computed(() =>
  props.article.sender?.name === EnumTicketArticleSenderName.Customer
    ? 'right'
    : 'left',
)

const isArticleTypeNote = computed(() => props.article.type?.name === 'note')

const {
  frameBorderClass,
  dividerClass,
  bodyClasses,
  headerAndIconBarBackgroundClass,
  articleWrapperBorderClass,
} = useBubbleStyleGuide(position, isArticleTypeNote)

const filteredAttachments = computed(() => {
  return props.article.attachmentsWithoutInline.filter(
    (file) => !file.preferences || !file.preferences['original-format'],
  )
})

const { attachments: articleAttachments } = useArticleAttachments({
  ticketInternalId: ticket.value?.internalId,
  articleInternalId: props.article?.internalId,
  attachments: filteredAttachments,
})

const inlineImages = ref<ImageViewerFile[]>([])

const { showImage } = useImageViewer(
  computed(() => [...inlineImages.value, ...articleAttachments.value]),
)
</script>

<template>
  <article
    class="backface-hidden relative rounded-t-xl"
    :class="[
      {
        'bg-stripes relative z-0 rounded-xl outline outline-1 outline-blue-700 ltr:rounded-bl-none rtl:rounded-br-none':
          isArticleTypeNote,
        'ltr:rounded-bl-xl rtl:rounded-br-xl': position === 'right',
        'ltr:rounded-br-xl rtl:rounded-bl-xl': position === 'left',
      },
      frameBorderClass,
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
        class="grid w-full grid-rows-[0fr] overflow-hidden rounded-t-xl"
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

      <ArticleBubbleBody
        tabindex="0"
        :data-test-id="`article-bubble-body-${article.internalId}`"
        class="focus:outline-none focus-visible:-outline-offset-2 focus-visible:outline-blue-800"
        :class="[bodyClasses, { 'pt-3': showMetaInformation }]"
        :position="position"
        :show-meta-information="showMetaInformation"
        :inline-images="inlineImages"
        :article="article"
        @click="toggleHeader"
        @keydown.enter="toggleHeader"
        @preview="showImage"
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
        @preview="showImage"
      />
    </div>

    <ArticleBubbleActionList :article="article" :position="position" />
  </article>
</template>

<style scoped>
.bg-stripes::before {
  @apply rounded-2xl ltr:rounded-bl-none rtl:rounded-br-none;

  content: '';
  background-image: repeating-linear-gradient(
    45deg,
    theme('colors.blue.400'),
    theme('colors.blue.400') 5px,
    theme('colors.blue.700') 5px,
    theme('colors.blue.700') 10px
  );
  height: calc(100% + 10px);
  width: calc(100% + 10px);
  left: -5px;
  top: -5px;
  position: absolute;
  z-index: -10;
}

[data-theme='dark'] .bg-stripes::before {
  background-image: repeating-linear-gradient(
    45deg,
    theme('colors.blue.700'),
    theme('colors.blue.700') 5px,
    theme('colors.blue.900') 5px,
    theme('colors.blue.900') 10px
  );
}

.pseudo-transition {
  &-enter-active,
  &-leave-active {
    transition: transform 0.3s ease;
  }

  &-enter-from,
  &-leave-to {
    transform: translateY(0);
  }
}
</style>
