<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useElementVisibility } from '@vueuse/core'
import { storeToRefs } from 'pinia'
import { computed, ref, toRef, useTemplateRef, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'
import { scrollIntoView } from '#shared/utils/dom.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonFloatingToolbar from '#desktop/components/CommonFloatingToolbar/CommonFloatingToolbar.vue'
import CommonIndicator from '#desktop/components/CommonIndicator/CommonIndicator.vue'
import { useIndicator } from '#desktop/components/CommonIndicator/useIndicator.ts'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'
import { SidebarName } from '#desktop/components/layout/types.ts'
import { useScrollPosition } from '#desktop/composables/useScrollPosition.ts'
import { useKnowledgeBaseAnswerDelete } from '#desktop/entities/knowledge-base/composables/useKnowledgeBaseAnswerDelete.ts'

import KnowledgeBaseAnswerAttachments from '../components/KnowledgeBaseAnswer/KnowledgeBaseAnswerAttachments.vue'
import KnowledgeBaseAnswerContent from '../components/KnowledgeBaseAnswer/KnowledgeBaseAnswerContent.vue'
import KnowledgeBaseAnswerContentSkeleton from '../components/KnowledgeBaseAnswer/KnowledgeBaseAnswerContentSkeleton.vue'
import KnowledgeBaseAnswerSidebar from '../components/KnowledgeBaseAnswer/KnowledgeBaseAnswerSidebar/KnowledgeBaseAnswerSidebar.vue'
import KnowledgeBaseAnswerSidebarContent from '../components/KnowledgeBaseAnswer/KnowledgeBaseAnswerSidebar/KnowledgeBaseAnswerSidebarContent.vue'
import { READING_COLUMN_CLASS } from '../components/KnowledgeBaseTopBarHeader/headerClasses.ts'
import KnowledgeBaseAnswerTopBarHeader from '../components/KnowledgeBaseTopBarHeader/KnowledgeBaseAnswerTopBarHeader.vue'
import { useKnowledgeBaseAnswer } from '../composables/useKnowledgeBaseAnswer.ts'
import { useKnowledgeBaseAnswerEditAction } from '../composables/useKnowledgeBaseAnswerEditAction.ts'
import { useKnowledgeBaseFeedAction } from '../composables/useKnowledgeBaseFeedAction.ts'
import { knowledgeBaseSearchReturnRoute } from '../utils/knowledgeBaseSearchReturn.ts'

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

useScrollPosition(contentContainerElement)

const route = useRoute()
const router = useRouter()

const { localeData } = storeToRefs(useLocaleStore())

const searchReturnRoute = computed(() =>
  knowledgeBaseSearchReturnRoute(props.localeCode, route.query),
)

// Offered here as the toolbar's primary action, and in the sidebar's action menu - one gate for
//   both (useKnowledgeBaseAnswerEditAction).
const { canEdit, editAnswer } = useKnowledgeBaseAnswerEditAction({
  answer,
  localeCode: toRef(props, 'localeCode'),
})

// The answer's own category, so its feed is offered like in the old interface.
const { feedActions } = useKnowledgeBaseFeedAction(computed(() => answer.value?.category?.id))

const { confirmAnswerDelete } = useKnowledgeBaseAnswerDelete()

// What the sidebar's action menu offers, built here rather than in the header: the design puts the
//   menu in the sidebar (its header, beside the section title), and the actions act on the answer
//   this view holds - not on anything the header owns.
//
// Editing first: it is what an editor comes here for, while the feed is a subscription for readers.
//   Deleting last, behind a separator: it is the destructive one, and nothing below it.
const actions = computed<MenuItem[]>(() => {
  const currentAnswer = answer.value

  const items: MenuItem[] = [...feedActions.value]

  if (canEdit.value) {
    items.unshift({
      key: 'edit-answer',
      label: __('Edit answer'),
      icon: 'pencil',
      onClick: () => editAnswer(),
    })
  }

  if (currentAnswer?.policy.destroy) {
    items.push({
      key: 'delete-answer',
      label: __('Delete answer'),
      icon: 'trash3',
      variant: 'danger',
      separatorTop: true,
      // Deleting the page being read, so it hands over where to go instead.
      onClick: () =>
        confirmAnswerDelete(
          { id: currentAnswer.id, title: currentAnswer.translation?.title },
          { categoryId: currentAnswer.category.id },
        ),
    })
  }

  return items
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

const editAnswerButtonElement = useTemplateRef('edit-answer-button')
const isEditAnswerButtonVisible = ref(false)

const showEditAnswerButtonAction = computed(() => canEdit.value && !isEditAnswerButtonVisible.value)

watch(
  useElementVisibility(editAnswerButtonElement),
  (visible) => {
    isEditAnswerButtonVisible.value = visible
  },
  { immediate: true },
)
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
      <section class="mx-auto mb-5 w-full min-w-xs py-5" :class="READING_COLUMN_CLASS">
        <CommonLoader :loading="loading">
          <template #skeleton>
            <KnowledgeBaseAnswerContentSkeleton />
          </template>

          <div class="space-y-7">
            <KnowledgeBaseAnswerContent :content="answer?.translation?.content" />

            <KnowledgeBaseAnswerAttachments :attachments="answer?.attachments" />
          </div>
        </CommonLoader>
      </section>

      <CommonButton
        v-if="canEdit"
        ref="edit-answer-button"
        variant="tertiary"
        prefix-icon="pencil"
        size="small"
        @click="editAnswer"
      >
        {{ $t('Edit answer') }}
      </CommonButton>

      <CommonIndicator v-model="isReachingBottom" />

      <!-- Three states, in one box: `mt-auto` takes the free space of the column, so an answer
           too short to scroll leaves the toolbar at the bottom of the content area rather than
           hanging right under its last line; with more content than fits there is no free space
           left and `sticky bottom-3` floats it above the fold instead; and being in the flow
           rather than in a zero-height wrapper, it no longer covers the end of the answer at
           full scroll. `pointer-events-none` on the wrapper, since its box spans the column
           while it sticks. -->
      <div
        class="pointer-events-none sticky bottom-3 mt-auto flex w-full justify-end px-3 pt-3 print:hidden"
      >
        <CommonButton
          v-if="searchReturnRoute"
          class="pointer-events-auto me-auto"
          size="medium"
          variant="tertiary"
          :prefix-icon="localeData?.dir === 'rtl' ? 'chevron-right' : 'chevron-left'"
          @click="router.push(searchReturnRoute)"
        >
          {{ $t('Back to search results') }}
        </CommonButton>

        <CommonFloatingToolbar
          :label="$t('Answer actions')"
          :is-reaching-bottom="isReachingBottom"
          :is-reaching-top="isReachingTop"
          :hide-primary-action="!showEditAnswerButtonAction"
          class="pointer-events-auto"
          @scroll-to-start="scrollToStart"
          @scroll-to-end="scrollToEnd"
        >
          <!-- `primary-action` rather than the default slot: filling the default one sets the
               toolbar's `hasGenericActions` and takes its scroll buttons away. -->
          <template #primary-action>
            <CommonButton
              v-tooltip="$t('Edit answer')"
              size="medium"
              variant="tertiary"
              icon="pencil"
              class="rounded-[(--toolbar-radius)-(--toolbar-p)]! border! border-neutral-100 dark:border-gray-900"
              @click="editAnswer"
            />
          </template>
        </CommonFloatingToolbar>
      </div>
    </div>

    <template #sideBar>
      <KnowledgeBaseAnswerSidebar
        :name="SidebarName.KnowledgeBaseAnswer"
        :title="__('Knowledge base answer')"
        icon="file-richtext"
        :actions="actions"
        :entity="answer"
      >
        <KnowledgeBaseAnswerSidebarContent v-if="answer" :answer="answer" />
      </KnowledgeBaseAnswerSidebar>
    </template>
  </LayoutContent>
</template>
