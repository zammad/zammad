<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonDialog from '@mobile/components/CommonDialog/CommonDialog.vue'
import CommonSectionMenu from '@mobile/components/CommonSectionMenu/CommonSectionMenu.vue'
import CommonSectionMenuItem from '@mobile/components/CommonSectionMenu/CommonSectionMenuItem.vue'
import { computed } from 'vue'
import ArticleMetadataAddress from './ArticleMetadataAddress.vue'
import type { TicketArticle } from '../../types/tickets'

interface Props {
  name: string
  article: TicketArticle
  ticketInternalId: number
}

const props = defineProps<Props>()

const channelIcon = computed(() => {
  return props.article.type?.name?.split(' ')[0]
})

const links = computed(() => {
  const { article } = props
  // Example for usage: https://github.com/zammad/zammad/blob/develop/app/jobs/communicate_twitter_job.rb#L65
  const links = [...(article.preferences?.links || [])]
  if (article.type?.name === 'email') {
    links.push({
      label: __('Raw'),
      api: true,
      url: `/ticket_article_plain/${article.internalId}`,
      target: '_blank',
    })
  }
  article.attachments.forEach((file) => {
    if (file.preferences?.['original-format'] !== true) {
      return
    }
    const articleInternalId = props.article.internalId
    const attachmentInternalId = file.internalId
    const { ticketInternalId } = props
    const url = `/ticket_attachment/${ticketInternalId}/${articleInternalId}/${attachmentInternalId}?disposition=attachment`
    links.push({
      label: __('Original Formatting'),
      api: true,
      url,
      target: '_blank',
    })
  })
  return links
})
</script>

<template>
  <CommonDialog :label="__('Meta Data')" :name="name" class="px-4">
    <CommonSectionMenu>
      <ArticleMetadataAddress :address="article.from" :label="__('From')" />
      <ArticleMetadataAddress
        :address="article.replyTo"
        :label="__('Reply-To')"
      />
      <ArticleMetadataAddress :address="article.to" :label="__('To')" />
      <ArticleMetadataAddress :address="article.cc" :label="__('CC')" />
      <CommonSectionMenuItem v-if="article.subject" :label="__('Subject')">
        <div>{{ article.subject }}</div>
      </CommonSectionMenuItem>
      <CommonSectionMenuItem v-if="article.type?.name" :label="__('Channel')">
        <span class="inline-flex items-center gap-1">
          <CommonIcon
            v-if="channelIcon"
            :name="channelIcon"
            size="tiny"
            class="inline"
          />
          {{ $t(article.type.name) }}
        </span>
        <div class="leading-3">
          <CommonLink
            v-for="{ url, api, label, target } of links"
            :key="url"
            :link="url"
            :rest-api="api"
            :target="target"
            class="text-sm text-white/75 after:inline after:content-['|'] last:after:hidden ltr:after:ml-1 rtl:after:mr-1"
          >
            {{ $t(label) }}
          </CommonLink>
        </div>
      </CommonSectionMenuItem>
      <CommonSectionMenuItem :label="__('Sent')">
        <CommonDateTime :date-time="article.createdAt" type="absolute" />
      </CommonSectionMenuItem>
    </CommonSectionMenu>
  </CommonDialog>
</template>
