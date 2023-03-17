<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { getArticleChannelIcon } from '@shared/entities/ticket-article/composables/getArticleChannelIcon'
import CommonDialog from '@mobile/components/CommonDialog/CommonDialog.vue'
import CommonSectionMenu from '@mobile/components/CommonSectionMenu/CommonSectionMenu.vue'
import CommonSectionMenuItem from '@mobile/components/CommonSectionMenu/CommonSectionMenuItem.vue'
import { computed } from 'vue'
import { i18n } from '@shared/i18n'
import type { TicketArticle } from '@shared/entities/ticket/types'
import ArticleMetadataAddress from './ArticleMetadataAddress.vue'

interface Props {
  name: string
  article: TicketArticle
  ticketInternalId: number
}

const props = defineProps<Props>()

const channelIcon = computed(() => {
  const name = props.article.type?.name
  if (name) return getArticleChannelIcon(name)
  return undefined
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
  article.attachmentsWithoutInline.forEach((file) => {
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

const sign = computed(() => {
  const security = props.article.securityState
  if (!security || security.signingSuccess == null) return null
  return {
    message: security.signingMessage,
    success: security.signingSuccess,
  }
})

const encryptionMessage = computed(() => {
  const security = props.article.securityState
  if (!security?.encryptionSuccess) return null
  let message = i18n.t('Encrypted')
  if (security.encryptionMessage)
    message += ` (${i18n.t(security.encryptionMessage)})`
  return message
})
</script>

<template>
  <CommonDialog :label="__('Meta Data')" :name="name" class="p-4">
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
            class="text-sm text-white/75 after:inline after:content-['|'] last:after:hidden ltr:mr-1 ltr:after:ml-1 rtl:ml-1 rtl:after:mr-1"
          >
            {{ $t(label) }}
          </CommonLink>
        </div>
      </CommonSectionMenuItem>
      <CommonSectionMenuItem :label="__('Sent')">
        <CommonDateTime :date-time="article.createdAt" type="absolute" />
      </CommonSectionMenuItem>
      <!-- app/assets/javascripts/app/views/ticket_zoom/article_view.jst.eco:34 -->
      <CommonSectionMenuItem
        v-if="sign || encryptionMessage"
        :label="__('Security')"
      >
        <div class="flex gap-1">
          <span v-if="encryptionMessage" class="inline-flex items-center gap-1">
            <CommonIcon name="mobile-lock" size="tiny" />
            {{ encryptionMessage }}
          </span>
          <span
            v-if="sign"
            class="inline-flex items-center gap-1"
            :class="{ 'text-orange': !sign.success }"
          >
            <CommonIcon
              :name="sign.success ? 'mobile-signed' : 'mobile-not-signed'"
              size="tiny"
            />
            {{ sign.success ? $t('Signed') : $t('Unsigned') }}
            {{ sign.message ? ` (${sign.message})` : '' }}
          </span>
        </div>
      </CommonSectionMenuItem>
    </CommonSectionMenu>
  </CommonDialog>
</template>
