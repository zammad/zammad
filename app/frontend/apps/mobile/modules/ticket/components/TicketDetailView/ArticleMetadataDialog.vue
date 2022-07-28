<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonDialog from '@mobile/components/CommonDialog/CommonDialog.vue'
import CommonSectionMenu from '@mobile/components/CommonSectionMenu/CommonSectionMenu.vue'
import CommonSectionMenuItem from '@mobile/components/CommonSectionMenu/CommonSectionMenuItem.vue'
import { computed } from 'vue'
import type { TicketArticle } from '../../types/tickets'

interface Props {
  name: string
  article: TicketArticle
}

const props = defineProps<Props>()

const channelIcon = computed(() => {
  return props.article.type?.name?.split(' ')[0]
})

const links = computed(() => {
  const { article } = props
  const links = []
  if (article.type?.name === 'email') {
    links.push({
      label: __('Raw'),
      api: true,
      url: `/ticket_article_plain/${article.internalId}`,
    })
  }

  // TODO preferences link:
  // app/assets/javascripts/app/controllers/ticket_zoom/article_view.coffee:141
  // Example for usage: https://github.com/zammad/zammad/blob/develop/app/jobs/communicate_twitter_job.rb#L65
  return links
})
</script>

<template>
  <CommonDialog :label="__('Meta Data')" :name="name" class="px-4">
    <CommonSectionMenu>
      <!-- TODO return in a different format: https://github.com/zammad/coordination-feature-mobile-view/issues/151 -->
      <CommonSectionMenuItem v-if="article.from" :label="__('From')">
        <div>{{ article.from.raw }}</div>
      </CommonSectionMenuItem>
      <CommonSectionMenuItem v-if="article.replyTo" :label="__('Reply-To')">
        <div>{{ article.replyTo.raw }}</div>
      </CommonSectionMenuItem>
      <CommonSectionMenuItem v-if="article.to" :label="__('To')">
        <div>{{ article.to.raw }}</div>
      </CommonSectionMenuItem>
      <CommonSectionMenuItem v-if="article.cc" :label="__('CC')">
        <div>{{ article.cc.raw }}</div>
      </CommonSectionMenuItem>
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
            v-for="{ url, api, label } of links"
            :key="url"
            :link="url"
            :rest-api="api"
            open-in-new-tab
            class="text-sm text-white/75 after:inline after:content-['|'] last:after:hidden ltr:after:ml-1 rtl:after:mr-1"
          >
            {{ $t(label) }}
          </CommonLink>
        </div>
      </CommonSectionMenuItem>
      <CommonSectionMenuItem :label="__('Sent')">
        <CommonDateTime :date-time="article.createdAt" format="absolute" />
      </CommonSectionMenuItem>
    </CommonSectionMenu>
  </CommonDialog>
</template>
