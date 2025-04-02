<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
/* eslint-disable vue/no-v-html */

import { computed, nextTick, onMounted, ref, watch } from 'vue'

import CommonFilePreview from '#shared/components/CommonFilePreview/CommonFilePreview.vue'
import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import { useArticleToggleMore } from '#shared/composables/useArticleToggleMore.ts'
import { useAttachments } from '#shared/composables/useAttachments.ts'
import { useHtmlInlineImages } from '#shared/composables/useHtmlInlineImages.ts'
import { useHtmlLinks } from '#shared/composables/useHtmlLinks.ts'
import type { ImageViewerFile } from '#shared/composables/useImageViewer.ts'
import { useImageViewer } from '#shared/composables/useImageViewer.ts'
import type { Attachment } from '#shared/entities/attachment/types.ts'
import type {
  TicketArticleSecurityState,
  TicketArticlesQuery,
} from '#shared/graphql/types.ts'
import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'
import { i18n } from '#shared/i18n.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import type { ConfidentTake } from '#shared/types/utils.ts'
import stopEvent from '#shared/utils/events.ts'
import { textToHtml } from '#shared/utils/helpers.ts'

import { useArticleSeen } from '../../composable/useArticleSeen.ts'

import ArticleReactionBadge from './ArticleReactionBadge.vue'
import ArticleRemoteContentBadge from './ArticleRemoteContentBadge.vue'
import ArticleSecurityBadge from './ArticleSecurityBadge.vue'
import ArticleWhatsappMediaBadge from './ArticleWhatsappMediaBadge.vue'

interface Props {
  position: 'left' | 'right'
  content: string
  internal: boolean
  user?: Maybe<ConfidentTake<TicketArticlesQuery, 'articles.edges.node.author'>>
  security?: Maybe<TicketArticleSecurityState>
  contentType: string
  ticketInternalId: number
  articleId: string
  attachments: Attachment[]
  remoteContentWarning?: string
  mediaError?: boolean | null
  reaction?: string
}

const props = defineProps<Props>()
const emit = defineEmits<{
  'show-context': []
  seen: []
}>()

const session = useSessionStore()

const colorClasses = computed(() => {
  const { internal, position } = props

  if (internal) return 'border border-blue bg-black'
  if (position === 'left') return 'border border-black bg-white text-black'
  return 'border border-black bg-blue text-black'
})

const bubbleClasses = computed(() => {
  const { internal, position } = props

  if (internal) return undefined

  return {
    'rounded-bl-sm': position === 'left',
    'rounded-br-sm': position === 'right',
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
      top: body.value.length ? 'border-t-[0.5px] border-t-white/50' : '',
      amount: 'text-white/60',
      file: 'border-white/40',
      icon: 'border-white/40',
    }
  }
  return {
    top: body.value.length ? 'border-t-[0.5px] border-black' : '',
    amount: 'text-black/60',
    file: 'border-black',
    icon: 'border-black',
  }
})

const { shownMore, bubbleElement, hasShowMore, toggleShowMore } =
  useArticleToggleMore()

const articleInternalId = computed(() => getIdFromGraphQLId(props.articleId))

const { attachments: articleAttachments } = useAttachments({
  attachments: computed(() => props.attachments),
})

const inlineImages = ref<ImageViewerFile[]>([])

const { showImage } = useImageViewer(
  computed(() => [...inlineImages.value, ...articleAttachments.value]),
)

const previewImage = (event: Event, attachment: Attachment) => {
  stopEvent(event)
  showImage(attachment)
}

const { setupLinksHandlers } = useHtmlLinks('/mobile')
const { populateInlineImages } = useHtmlInlineImages(inlineImages, (index) =>
  showImage(inlineImages.value[index]),
)

watch(
  () => props.content,
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

useArticleSeen(bubbleElement, emit)

const onContextClick = () => {
  emit('show-context')
  nextTick(() => {
    // remove selection because pointerdown event will leave it as is,
    // all actions inside the context should already have accessed it synchronously
    window.getSelection()?.removeAllRanges()
  })
}
</script>

<template>
  <!-- It is the correct role comment -->
  <!-- eslint-disable vuejs-accessibility/aria-role -->
  <div
    :id="`article-${articleInternalId}`"
    role="comment"
    class="Article relative flex pb-4"
    :class="{
      Internal: internal,
      'Right flex-row-reverse': position === 'right',
      Left: position === 'left',
    }"
    :data-created-by="user?.id"
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
    <div class="Border">
      <div
        class="content flex flex-col overflow-hidden rounded-3xl px-4 pt-2 pb-3"
        :class="[bubbleClasses, colorClasses]"
      >
        <div
          class="flex items-center text-xs font-bold"
          data-test-id="article-username"
        >
          <span class="truncate break-words">
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
            BubbleGradient: hasShowMore && !shownMore,
          }"
        ></div>
        <div
          v-if="attachments.length"
          class="mt-1 mb-2"
          :class="colorsClasses.top"
        >
          <div class="py-1 text-xs" :class="colorsClasses.amount">
            {{
              attachments.length === 1
                ? $t('1 attached file')
                : $t('%s attached files', attachments.length)
            }}
          </div>
          <CommonFilePreview
            v-for="attachment of articleAttachments"
            :key="attachment.internalId"
            :file="attachment"
            :download-url="attachment.downloadUrl"
            :preview-url="attachment.preview"
            :no-preview="!$c.ui_ticket_zoom_attachments_preview"
            :wrapper-class="colorsClasses.file"
            :icon-class="colorsClasses.icon"
            :size-class="colorsClasses.amount"
            no-remove
            @preview="previewImage($event, attachment)"
          />
        </div>
        <div
          class="absolute bottom-0 flex gap-1"
          :class="[
            position === 'left'
              ? 'flex-row-reverse ltr:left-10 rtl:right-10'
              : 'ltr:right-10 rtl:left-10',
          ]"
        >
          <ArticleReactionBadge
            v-if="reaction"
            :class="[colorClasses]"
            :reaction="reaction"
          />
          <ArticleWhatsappMediaBadge
            v-if="props.mediaError"
            :article-id="articleId"
            :media-error="props.mediaError"
          />
          <ArticleSecurityBadge
            v-if="security"
            :article-id="articleId"
            :success-class="colorClasses"
            :security="security"
          />
          <ArticleRemoteContentBadge
            v-if="remoteContentWarning"
            :class="colorClasses"
            :original-formatting-url="remoteContentWarning"
          />
          <button
            v-if="hasShowMore"
            :class="[
              colorClasses,
              'flex h-7 items-center justify-center rounded-md px-2 font-semibold',
            ]"
            type="button"
            @click="toggleShowMore()"
            @keydown.enter.prevent="toggleShowMore()"
          >
            {{ shownMore ? $t('See less') : $t('See more') }}
          </button>
          <button
            :class="[
              colorClasses,
              'flex h-7 w-7 items-center justify-center rounded-md',
            ]"
            type="button"
            data-name="article-context"
            :aria-label="$t('Article actions')"
            @pointerdown="onContextClick()"
            @keydown.enter.prevent="onContextClick()"
          >
            <CommonIcon
              name="more-vertical"
              size="small"
              decorative
              data-ignore-click
            />
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.Content {
  word-break: normal;
  overflow-wrap: anywhere;
}

.Article:not(.Internal) {
  &.Right .Content,
  &.Left .Content {
    :deep(a) {
      color: var(--color-black);
      text-decoration: underline;
    }
  }
}

.BubbleGradient::before {
  content: '';
  position: absolute;
  left: 0;
  right: 0;
  bottom: 0;
  height: 50px;
  pointer-events: none;
}

.Right:not(.Internal) .BubbleGradient::before {
  background: linear-gradient(rgba(255, 255, 255, 0), var(--color-blue));
}

.Left:not(.Internal) .BubbleGradient::before {
  background: linear-gradient(rgba(255, 255, 255, 0), var(--color-white));
}

.Border {
  overflow: hidden;
}

.Internal .Border {
  background: repeating-linear-gradient(
    45deg,
    var(--color-blue),
    var(--color-blue) 5px,
    var(--color-blue-dark) 5px,
    var(--color-blue-dark) 10px
  );
  background-size: 14px 14px;
  background-position: -1px;
  padding: 4px;
  border-radius: calc(1.5rem + 4px);
  margin: -4px;
}

.Internal .BubbleGradient::before {
  background: linear-gradient(rgba(255, 255, 255, 0), var(--color-black));
}
</style>
