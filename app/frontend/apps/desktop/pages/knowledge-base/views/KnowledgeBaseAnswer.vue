<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef, useTemplateRef } from 'vue'

import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { scrollIntoView } from '#shared/utils/dom.ts'

import CommonFloatingToolbar from '#desktop/components/CommonFloatingToolbar/CommonFloatingToolbar.vue'
import CommonIndicator from '#desktop/components/CommonIndicator/CommonIndicator.vue'
import { useIndicator } from '#desktop/components/CommonIndicator/useIndicator.ts'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'
import { SidebarName } from '#desktop/components/layout/types.ts'

import KnowledgeBaseAnswerAttachments from '../components/KnowledgeBaseAnswer/KnowledgeBaseAnswerAttachments.vue'
import KnowledgeBaseAnswerContent from '../components/KnowledgeBaseAnswer/KnowledgeBaseAnswerContent.vue'
import KnowledgeBaseAnswerContentSkeleton from '../components/KnowledgeBaseAnswer/KnowledgeBaseAnswerContentSkeleton.vue'
import KnowledgeBaseAnswerSidebar from '../components/KnowledgeBaseAnswer/KnowledgeBaseAnswerSidebar/KnowledgeBaseAnswerSidebar.vue'
import KnowledgeBaseAnswerSidebarContent from '../components/KnowledgeBaseAnswer/KnowledgeBaseAnswerSidebar/KnowledgeBaseAnswerSidebarContent.vue'
import { READING_COLUMN_CLASS } from '../components/KnowledgeBaseTopBarHeader/headerClasses.ts'
import KnowledgeBaseAnswerTopBarHeader from '../components/KnowledgeBaseTopBarHeader/KnowledgeBaseAnswerTopBarHeader.vue'
import { useKnowledgeBaseAnswer } from '../composables/useKnowledgeBaseAnswer.ts'

const props = defineProps<{
  localeCode?: string
  answerInternalId?: string
}>()

const contentContainerElement = useTemplateRef('content-container')

const answerId = computed(() =>
  props.answerInternalId
    ? convertToGraphQLId('KnowledgeBase::Answer', props.answerInternalId)
    : undefined,
)

const { answer, loading } = useKnowledgeBaseAnswer({
  answerId,
  locale: toRef(props, 'localeCode'),
})

const { isIntersecting: isReachingBottom } = useIndicator()
const { isIntersecting: isReachingTop } = useIndicator()

const scrollToStart = () => {
  scrollIntoView(contentContainerElement.value, 'start', {
    behavior: 'instant',
  })
}
const scrollToEnd = () => {
  scrollIntoView(contentContainerElement.value, 'end', {
    behavior: 'instant',
  })
}
</script>

<template>
  <LayoutContent
    background-variant="primary"
    content-alignment="center"
    name="knowledge-base"
    show-sidebar
    :sidebar-name="SidebarName.KnowledgeBaseAnswer"
    no-scrollable
    no-padding
  >
    <div
      ref="content-container"
      class="@container flex size-full flex-col items-center overflow-y-auto"
    >
      <CommonIndicator v-model="isReachingTop" class="translate-y-1" />

      <KnowledgeBaseAnswerTopBarHeader
        :content-container-element="contentContainerElement"
        :answer="answer"
        :loading="loading"
      />

      <!-- Similar to the column of the ticket article list (ArticleList.vue), so an
           answer reads at the same measure as an article — and shared verbatim with
           the header title/details above, so both stay aligned at any width. -->
      <section class="mx-auto w-full min-w-xs py-5" :class="READING_COLUMN_CLASS">
        <CommonLoader :loading="loading">
          <template #skeleton>
            <KnowledgeBaseAnswerContentSkeleton />
          </template>

          <div class="space-y-7">
            <KnowledgeBaseAnswerContent :content="answer?.content" />

            <KnowledgeBaseAnswerAttachments :attachments="answer?.attachments" />
          </div>
        </CommonLoader>
      </section>

      <CommonIndicator v-model="isReachingBottom" />

      <div class="pointer-none sticky bottom-3 h-0 w-full print:hidden">
        <CommonFloatingToolbar
          :label="$t('Answer actions')"
          :is-reaching-bottom="isReachingBottom"
          :is-reaching-top="isReachingTop"
          class="absolute inset-e-3 bottom-0"
          @scroll-to-start="scrollToStart"
          @scroll-to-end="scrollToEnd"
        >
          <!-- TODO <template #action>
            <CommonButton/>
          </template> -->
        </CommonFloatingToolbar>
      </div>
    </div>

    <template #sideBar>
      <KnowledgeBaseAnswerSidebar
        :name="SidebarName.KnowledgeBaseAnswer"
        :title="__('KB Answer')"
        icon="file-richtext"
      >
        <KnowledgeBaseAnswerSidebarContent v-if="answer" :answer="answer" />
      </KnowledgeBaseAnswerSidebar>
    </template>
  </LayoutContent>
</template>
