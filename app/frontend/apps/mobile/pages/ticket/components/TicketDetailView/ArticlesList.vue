<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { toRef, shallowRef } from 'vue'

import type {
  TicketArticle,
  TicketById,
} from '#shared/entities/ticket/types.ts'
import { EnumTicketArticleSenderName } from '#shared/graphql/types.ts'

import CommonSectionPopup from '#mobile/components/CommonSectionPopup/CommonSectionPopup.vue'

import { useTicketArticleContext } from '../../composable/useTicketArticleContext.ts'
import { useTicketArticleRows } from '../../composable/useTicketArticlesRows.ts'
import { useTicketInformation } from '../../composable/useTicketInformation.ts'

import ArticleBubble from './ArticleBubble.vue'
import ArticleDeliveryMessage from './ArticleDeliveryMessage.vue'
import ArticleSeparatorDate from './ArticleSeparatorDate.vue'
import ArticleSeparatorMore from './ArticleSeparatorMore.vue'
import ArticleSeparatorNew from './ArticleSeparatorNew.vue'
import ArticleSystem from './ArticleSystem.vue'

interface Props {
  articles: TicketArticle[]
  ticket: TicketById
  totalCount: number
}

const props = defineProps<Props>()
const emit = defineEmits<{
  'load-previous': []
}>()

const { contextOptions, articleContextShown, showArticleContext } =
  useTicketArticleContext()

const articlesElement = shallowRef<HTMLElement>()

const { rows } = useTicketArticleRows(
  toRef(props, 'articles'),
  toRef(props, 'totalCount'),
)

const filterAttachments = (article: TicketArticle) => {
  return article.attachmentsWithoutInline.filter(
    (file) => !file.preferences || !file.preferences['original-format'],
  )
}

const remoteContentWarning = (article: TicketArticle): string | undefined => {
  if (!article.preferences?.remote_content_removed) return

  let originalFormattingUrl

  article.attachmentsWithoutInline.forEach((file) => {
    if (file.preferences?.['original-format'] !== true) {
      return
    }
    const articleInternalId = article.internalId
    const attachmentInternalId = file.internalId
    const ticketInternalId = props.ticket.internalId
    originalFormattingUrl = `/ticket_attachment/${ticketInternalId}/${articleInternalId}/${attachmentInternalId}?disposition=attachment`
  })

  return originalFormattingUrl
}

const { newArticlesIds } = useTicketInformation()

const markSeen = (id: string) => {
  newArticlesIds.delete(id)
}
</script>

<template>
  <section
    ref="articlesElement"
    role="group"
    aria-label="Articles"
    class="relative flex-1 space-y-4 px-4 pt-4"
  >
    <template v-for="(row, idx) in rows" :key="row.key">
      <ArticleBubble
        v-if="row.type === 'article-bubble'"
        :content="row.article.bodyWithUrls"
        :user="row.article.author"
        :internal="row.article.internal"
        :content-type="row.article.contentType"
        :position="
          row.article.sender?.name !== EnumTicketArticleSenderName.Customer
            ? 'left'
            : 'right'
        "
        :media-error="row.article.mediaErrorState?.error"
        :security="row.article.securityState"
        :ticket-internal-id="ticket.internalId"
        :article-id="row.article.id"
        :attachments="filterAttachments(row.article)"
        :remote-content-warning="remoteContentWarning(row.article)"
        :reaction="row.article.preferences?.whatsapp?.reaction?.emoji"
        @seen="markSeen(row.key)"
        @show-context="showArticleContext(row.article, ticket)"
      />
      <ArticleDeliveryMessage
        v-if="row.type === 'delivery'"
        :content="row.content"
        :gap="rows[idx - 1]?.type === 'article-bubble' ? 'big' : 'small'"
        @seen="markSeen(row.key)"
      />
      <ArticleSystem
        v-if="row.type === 'system'"
        :to="row.to"
        :subject="row.subject"
        :reaction="row.reaction"
        @seen="markSeen(row.key)"
      />
      <ArticleSeparatorDate v-if="row.type === 'date'" :date="row.date" />
      <ArticleSeparatorNew v-if="row.type === 'new'" />
      <ArticleSeparatorMore
        v-if="row.type === 'more'"
        :count="row.count"
        @click="emit('load-previous')"
      />
    </template>
  </section>
  <CommonSectionPopup
    v-model:state="articleContextShown"
    :messages="contextOptions"
  />
</template>
