<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
/* eslint-disable vue/no-v-html */

import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import { computed, nextTick, onMounted, ref, watch } from 'vue'
import { i18n } from '#shared/i18n.ts'
import { textToHtml } from '#shared/utils/helpers.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import type {
  TicketArticleSecurityState,
  TicketArticlesQuery,
} from '#shared/graphql/types.ts'
import type { ConfidentTake } from '#shared/types/utils.ts'
import type { ImageViewerFile } from '#shared/composables/useImageViewer.ts'
import { useImageViewer } from '#shared/composables/useImageViewer.ts'
import CommonFilePreview from '#mobile/components/CommonFilePreview/CommonFilePreview.vue'
import stopEvent from '#shared/utils/events.ts'
import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'
import type { TicketArticleAttachment } from '#shared/entities/ticket/types.ts'
import { useRouter } from 'vue-router'
import { useApplicationStore } from '#shared/stores/application.ts'
import { isStandalone } from '#shared/utils/pwa.ts'
import { useArticleToggleMore } from '../../composable/useArticleToggleMore.ts'
import { useArticleAttachments } from '../../composable/useArticleAttachments.ts'
import ArticleSecurityBadge from './ArticleSecurityBadge.vue'
import ArticleWhatsappMediaBadge from './ArticleWhatsappMediaBadge.vue'
import { useArticleSeen } from '../../composable/useArticleSeen.ts'

interface Props {
  position: 'left' | 'right'
  content: string
  internal: boolean
  user?: Maybe<ConfidentTake<TicketArticlesQuery, 'articles.edges.node.author'>>
  security?: Maybe<TicketArticleSecurityState>
  contentType: string
  ticketInternalId: number
  articleId: string
  attachments: TicketArticleAttachment[]
  mediaError?: boolean | null
}

const props = defineProps<Props>()
const emit = defineEmits<{
  (e: 'showContext'): void
  (e: 'seen'): void
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

const { attachments: articleAttachments } = useArticleAttachments({
  ticketInternalId: props.ticketInternalId,
  articleInternalId: articleInternalId.value,
  attachments: computed(() => props.attachments),
})

const inlineAttachments = ref<ImageViewerFile[]>([])

const { showImage } = useImageViewer(
  computed(() => [...inlineAttachments.value, ...articleAttachments.value]),
)

const previewImage = (event: Event, attachment: TicketArticleAttachment) => {
  stopEvent(event)
  showImage(attachment)
}

const router = useRouter()
const app = useApplicationStore()

const getRedirectRoute = (url: URL): string | undefined => {
  if (url.pathname.startsWith('/mobile')) {
    return url.href.slice(`${url.origin}/mobile`.length)
  }

  const route = router.resolve(`/${url.hash.slice(1)}${url.search}`)
  if (route.name !== 'Error') {
    return route.fullPath
  }
}

const openLink = (target: string, path: string) => {
  // keep links inside PWA inside the app
  if (!isStandalone() && target && target !== '_self') {
    window.open(`/mobile${path}`, target)
  } else {
    router.push(path)
  }
}

const handleLinkClick = (link: HTMLAnchorElement, event: Event) => {
  const fqdnOrigin = `${window.location.protocol}//${app.config.fqdn}${
    window.location.port ? `:${window.location.port}` : ''
  }`
  try {
    const url = new URL(link.href)
    if (url.origin === window.location.origin || url.origin === fqdnOrigin) {
      const redirectRoute = getRedirectRoute(url)
      if (redirectRoute) {
        openLink(link.target, redirectRoute)
        event.preventDefault()
      }
    }
  } catch {
    // skip
  }
}

// user links has fqdn in its href, but if it changes the link becomes invalid
// to bypass that we replace the href with the correct one
const patchUserMentionLinks = (link: HTMLAnchorElement) => {
  const userId = link.dataset.mentionUserId
  if (userId) {
    link.href = `${window.location.origin}/mobile/users/${userId}`
  }
}

const setupLinksHandlers = (element: HTMLDivElement) => {
  const links = element.querySelectorAll('a')
  links.forEach((link) => {
    if ('__handled' in link) return
    Object.defineProperty(link, '__handled', { value: true })
    patchUserMentionLinks(link)
    link.addEventListener('click', (event) => handleLinkClick(link, event))
  })
}

const populateInlineAttachments = (element: HTMLDivElement) => {
  const images = element.querySelectorAll('img')
  inlineAttachments.value = []

  images.forEach((image) => {
    const mime = image.alt?.match(/\.(jpe?g)$/i) ? 'image/jpeg' : 'image/png'
    const preview: ImageViewerFile = {
      name: image.alt,
      inline: image.src,
      type: mime,
    }
    image.classList.add('cursor-pointer')
    const index = inlineAttachments.value.push(preview) - 1
    image.onclick = () => showImage(inlineAttachments.value[index])
  })
}

watch(
  () => props.content,
  async () => {
    await nextTick()
    if (bubbleElement.value) {
      setupLinksHandlers(bubbleElement.value)
      populateInlineAttachments(bubbleElement.value)
    }
  },
)

onMounted(() => {
  if (bubbleElement.value) {
    setupLinksHandlers(bubbleElement.value)
    populateInlineAttachments(bubbleElement.value)
  }
})

useArticleSeen(bubbleElement, emit)

const onContextClick = () => {
  emit('showContext')
  nextTick(() => {
    // remove selection because pointerdown event will leave it as is,
    // all actions inside the context should already have accessed it synchronously
    window.getSelection()?.removeAllRanges()
  })
}
</script>

<template>
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
        class="content flex flex-col overflow-hidden rounded-3xl px-4 pb-3 pt-2"
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
          class="mb-2 mt-1"
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
  word-break: break-word;
}

.Article:not(.Internal) {
  &.Right .Content,
  &.Left .Content {
    :deep(a) {
      @apply text-black underline;
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
  background: linear-gradient(
    rgba(255, 255, 255, 0),
    theme('colors.blue.DEFAULT')
  );
}

.Left:not(.Internal) .BubbleGradient::before {
  background: linear-gradient(rgba(255, 255, 255, 0), theme('colors.white'));
}

.Border {
  overflow: hidden;
}

.Internal .Border {
  background: repeating-linear-gradient(
    45deg,
    theme('colors.blue.DEFAULT'),
    theme('colors.blue.DEFAULT') 5px,
    theme('colors.blue.dark') 5px,
    theme('colors.blue.dark') 10px
  );
  background-size: 14px 14px;
  background-position: -1px;
  padding: 4px;
  border-radius: calc(1.5rem + 4px);
  margin: -4px;
}

.Internal .BubbleGradient::before {
  background: linear-gradient(
    rgba(255, 255, 255, 0),
    theme('colors.black.DEFAULT')
  );
}
</style>
