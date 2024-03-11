<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { toRef, shallowRef } from 'vue'
import CommonSectionPopup from '#mobile/components/CommonSectionPopup/CommonSectionPopup.vue'
import type {
  TicketArticle,
  TicketById,
} from '#shared/entities/ticket/types.ts'
import ArticleBubble from './ArticleBubble.vue'
import ArticleSeparatorNew from './ArticleSeparatorNew.vue'
import ArticleSeparatorMore from './ArticleSeparatorMore.vue'
import ArticleSeparatorDate from './ArticleSeparatorDate.vue'
import { useTicketArticleRows } from '../../composable/useTicketArticlesRows.ts'
import { useTicketArticleContext } from '../../composable/useTicketArticleContext.ts'
import ArticleSystem from './ArticleSystem.vue'
import ArticleDeliveryMessage from './ArticleDeliveryMessage.vue'
import { useTicketInformation } from '../../composable/useTicketInformation.ts'

interface Props {
  articles: TicketArticle[]
  ticket: TicketById
  totalCount: number
}

const props = defineProps<Props>()
const emit = defineEmits<{
  (e: 'loadPrevious'): void
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
        :position="row.article.sender?.name !== 'Customer' ? 'left' : 'right'"
        :media-error="row.article.mediaErrorState?.error"
        :security="row.article.securityState"
        :ticket-internal-id="ticket.internalId"
        :article-id="row.article.id"
        :attachments="filterAttachments(row.article)"
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
        @seen="markSeen(row.key)"
      />
      <ArticleSeparatorDate v-if="row.type === 'date'" :date="row.date" />
      <ArticleSeparatorNew v-if="row.type === 'new'" />
      <ArticleSeparatorMore
        v-if="row.type === 'more'"
        :count="row.count"
        @click="emit('loadPrevious')"
      />
    </template>
  </section>
  <CommonSectionPopup
    v-model:state="articleContextShown"
    :messages="contextOptions"
  />
</template>
