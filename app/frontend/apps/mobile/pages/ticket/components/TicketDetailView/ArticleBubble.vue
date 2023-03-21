<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
/* eslint-disable vue/no-v-html */

import CommonUserAvatar from '@shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import { computed, nextTick, onMounted, watch } from 'vue'
import { i18n } from '@shared/i18n'
import { textToHtml } from '@shared/utils/helpers'
import { useSessionStore } from '@shared/stores/session'
import type {
  TicketArticleSecurityState,
  TicketArticlesQuery,
} from '@shared/graphql/types'
import type { ConfidentTake } from '@shared/types/utils'
import useImageViewer from '@shared/composables/useImageViewer'
import CommonFilePreview from '@mobile/components/CommonFilePreview/CommonFilePreview.vue'
import stopEvent from '@shared/utils/events'
import { getIdFromGraphQLId } from '@shared/graphql/utils'
import type { TicketArticleAttachment } from '@shared/entities/ticket/types'
import { useRouter } from 'vue-router'
import { useApplicationStore } from '@shared/stores/application'
import { isStandalone } from '@shared/utils/pwa'
import { useArticleToggleMore } from '../../composable/useArticleToggleMore'
import { useArticleAttachments } from '../../composable/useArticleAttachments'
import ArticleSecurityBadge from './ArticleSecurityBadge.vue'

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
}

const props = defineProps<Props>()
const emit = defineEmits<{
  (e: 'showContext'): void
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
      top: 'border-t-[0.5px] border-t-white/50',
      amount: 'text-white/60',
      file: 'border-white/40',
      icon: 'border-white/40',
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

const articleInternalId = computed(() => getIdFromGraphQLId(props.articleId))

const { attachments: articleAttachments } = useArticleAttachments({
  ticketInternalId: props.ticketInternalId,
  articleInternalId: articleInternalId.value,
  attachments: computed(() => props.attachments),
})

const { showImage } = useImageViewer(articleAttachments)

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

watch(
  () => props.content,
  async () => {
    await nextTick()
    if (bubbleElement.value) setupLinksHandlers(bubbleElement.value)
  },
)

onMounted(() => {
  if (bubbleElement.value) setupLinksHandlers(bubbleElement.value)
})
</script>

<template>
  <div
    :id="`article-${articleInternalId}`"
    role="comment"
    class="Article relative flex"
    :class="{
      Internal: internal,
      'Right flex-row-reverse': position === 'right',
      Left: position === 'left',
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
      :class="[bubbleClasses, colorClasses]"
    >
      <div
        class="flex items-center text-xs font-bold"
        data-test-id="article-username"
      >
        <CommonIcon v-if="internal" size="xs" name="mobile-lock" />
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
        class="absolute -bottom-4 flex min-h-[24px] gap-1"
        :class="[
          position === 'left'
            ? 'flex-row-reverse ltr:left-10 rtl:right-10'
            : 'ltr:right-10 rtl:left-10',
        ]"
      >
        <ArticleSecurityBadge
          v-if="security"
          :article-id="articleId"
          :success-class="colorClasses"
          :security="security"
        />
        <button
          :class="[
            colorClasses,
            'flex h-6 w-6 items-center justify-center rounded-md',
          ]"
          type="button"
          data-name="article-context"
          :aria-label="$t('Article actions')"
          @click="emit('showContext')"
          @keydown.enter.prevent="emit('showContext')"
        >
          <CommonIcon name="mobile-more-vertical" size="tiny" decorative />
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
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

.bubbleGradient::before {
  content: '';
  position: absolute;
  left: 0;
  right: 0;
  bottom: 1.25rem;
  height: 30px;
  pointer-events: none;
}

.Right:not(.Internal) .bubbleGradient::before {
  background: linear-gradient(
    rgba(255, 255, 255, 0),
    theme('colors.blue.DEFAULT')
  );
}

.Left:not(.Internal) .bubbleGradient::before {
  background: linear-gradient(rgba(255, 255, 255, 0), theme('colors.white'));
}

.Internal .bubbleGradient::before {
  background: linear-gradient(
    rgba(255, 255, 255, 0),
    theme('colors.black.DEFAULT')
  );
}
</style>
