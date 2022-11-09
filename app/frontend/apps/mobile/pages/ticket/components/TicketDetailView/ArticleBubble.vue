<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
/* eslint-disable vue/no-v-html */

import CommonUserAvatar from '@shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import { computed } from 'vue'
import { i18n } from '@shared/i18n'
import { textToHtml } from '@shared/utils/helpers'
import { useSessionStore } from '@shared/stores/session'
import type { TicketArticlesQuery } from '@shared/graphql/types'
import type { ConfidentTake } from '@shared/types/utils'
import useImageViewer from '@shared/composables/useImageViewer'
import CommonFilePreview from '@mobile/components/CommonFilePreview/CommonFilePreview.vue'
import stopEvent from '@shared/utils/events'
import { useArticleToggleMore } from '../../composable/useArticleToggleMore'
import type { TicketArticleAttachment } from '../../types/tickets'
import { useArticleAttachments } from '../../composable/useArticleAttachments'

interface Props {
  position: 'left' | 'right'
  content: string
  internal: boolean
  user?: Maybe<
    ConfidentTake<TicketArticlesQuery, 'articles.edges.node.createdBy'>
  >
  contentType: string
  ticketInternalId: number
  articleInternalId: number
  attachments: TicketArticleAttachment[]
}

const props = defineProps<Props>()
const emit = defineEmits<{
  (e: 'showContext'): void
}>()

const session = useSessionStore()

const bubbleClasses = computed(() => {
  const { internal, position } = props

  if (internal) return 'border border-blue bg-black'

  return {
    'rounded-bl-sm bg-white text-black': position === 'left',
    'rounded-br-sm bg-blue text-black': position === 'right',
  }
})

const username = computed(() => {
  const { user } = props
  if (!user) return ''
  if (session.user?.id === user.id) {
    return i18n.t('Me')
  }
  return user.fullname
})

const body = computed(() => {
  if (props.contentType !== 'text/html') {
    return textToHtml(props.content)
  }
  return props.content
})

const colorsClasses = computed(() => {
  if (props.internal) {
    return {
      top: 'border-t-[0.5px] border-t-white/50',
      amount: 'text-white/60',
      file: 'border-white/40',
      icon: 'border-white/40',
    }
  }
  if (props.position === 'right') {
    return {
      top: 'border-t-[0.5px] border-white',
      amount: 'text-white/80',
      file: 'border-white',
      icon: 'border-white',
    }
  }
  return {
    top: 'border-t-[0.5px] border-black',
    amount: 'text-black/60',
    file: 'border-black',
    icon: 'border-black',
  }
})

const { shownMore, bubbleElement, hasShowMore, toggleShowMore } =
  useArticleToggleMore()

const { attachments: articleAttachments } = useArticleAttachments({
  ticketInternalId: props.ticketInternalId,
  articleInternalId: props.articleInternalId,
  attachments: computed(() => props.attachments),
})

const { showImage } = useImageViewer(articleAttachments)

const previewImage = (event: Event, attachment: TicketArticleAttachment) => {
  stopEvent(event)
  showImage(attachment)
}
</script>

<template>
  <div
    :id="`article-${articleInternalId}`"
    role="comment"
    class="Article relative flex"
    :class="{
      Internal: internal,
      Right: !internal && position === 'right',
      Left: !internal && position === 'left',
      'flex-row-reverse': position === 'right',
    }"
  >
    <div
      class="h-6 w-6 self-end"
      :class="{
        'ltr:mr-2 rtl:ml-2': position === 'left',
        'ltr:ml-2 rtl:mr-2': position === 'right',
      }"
    >
      <CommonUserAvatar v-if="user" size="xs" :entity="user" />
    </div>
    <div
      class="content flex flex-col overflow-hidden rounded-3xl px-4 py-2"
      :class="bubbleClasses"
    >
      <div
        class="flex text-xs font-bold text-black/90"
        data-test-id="article-username"
      >
        <CommonIcon v-if="internal" size="tiny" name="mobile-lock" />
        <span
          class="overflow-hidden text-ellipsis whitespace-nowrap break-words"
        >
          {{ username }}
        </span>
      </div>
      <div
        ref="bubbleElement"
        data-test-id="article-content"
        class="overflow-hidden text-base"
      >
        <div class="Content" v-html="body" />
      </div>
      <div
        v-if="hasShowMore"
        class="relative"
        :class="{
          bubbleGradient: hasShowMore && !shownMore,
          '-mb-3': !attachments.length,
        }"
      >
        <button
          class="h-5 text-xs"
          aria-hidden="true"
          @click="toggleShowMore()"
        >
          {{ shownMore ? $t('See less') : $t('See more') }}
        </button>
      </div>
      <div v-if="attachments.length" class="mt-1" :class="colorsClasses.top">
        <div class="py-1 text-xs" :class="colorsClasses.amount">
          {{
            attachments.length === 1
              ? $t('1 attached file')
              : $t('%s attached files', attachments.length)
          }}
        </div>
        <!--
            TODO action on click?
            app/assets/javascripts/app/controllers/ticket_zoom/article_view.coffee:147
            we would need internal ID for this url to work, or update url to allow GQL IDs
          -->
        <CommonFilePreview
          v-for="attachment of articleAttachments"
          :key="attachment.internalId"
          :file="attachment"
          :download-url="attachment.downloadUrl"
          :preview-url="attachment.content"
          :no-preview="!$c.ui_ticket_zoom_attachments_preview"
          :wrapper-class="colorsClasses.file"
          :icon-class="colorsClasses.icon"
          :size-class="colorsClasses.amount"
          no-remove
          @preview="previewImage($event, attachment)"
        />
      </div>
      <div class="flex h-3 justify-end">
        <button
          class="z-10"
          :title="$t('Article actions')"
          @click="emit('showContext')"
          @keydown.enter="emit('showContext')"
        >
          <CommonIcon name="mobile-more" size="tiny" decorative />
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
.Content {
  word-break: break-word;
}

.Article {
  &.Right .Content,
  &.Internal .Content {
    :deep(a) {
      @apply text-black underline;
    }
  }
}

.bubbleGradient::before {
  content: '';
  position: absolute;
  left: 0;
  right: 0;
  bottom: 1.25rem;
  height: 30px;
  pointer-events: none;
}

.Right .bubbleGradient::before {
  background: linear-gradient(
    rgba(255, 255, 255, 0),
    theme('colors.blue.DEFAULT')
  );
}

.Left .bubbleGradient::before {
  background: linear-gradient(rgba(255, 255, 255, 0), theme('colors.white'));
}

.Internal .bubbleGradient::before {
  background: linear-gradient(
    rgba(255, 255, 255, 0),
    theme('colors.black.DEFAULT')
  );
}
</style>
