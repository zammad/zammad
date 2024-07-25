<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import { useArticleSecurity } from '#shared/composables/useArticleSecurity.ts'
import { useWhatsapp } from '#shared/entities/ticket/channel/composables/useWhatsapp.ts'
import type { TicketArticle } from '#shared/entities/ticket/types.ts'
import { getArticleChannelIcon } from '#shared/entities/ticket-article/composables/getArticleChannelIcon.ts'
import { translateArticleSecurity } from '#shared/entities/ticket-article/composables/translateArticleSecurity.ts'

import CommonDialog from '#mobile/components/CommonDialog/CommonDialog.vue'
import CommonSectionMenu from '#mobile/components/CommonSectionMenu/CommonSectionMenu.vue'
import CommonSectionMenuItem from '#mobile/components/CommonSectionMenu/CommonSectionMenuItem.vue'

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

const { articleDeliveryStatus } = useWhatsapp(toRef(props.article))

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

const {
  signingIcon,
  signingMessage,
  encryptionMessage,
  isEncrypted,
  isSigned,
  hasSecurityAttribute,
  encryptionIcon,
  encryptedStatusMessage,
  signedStatusMessage,
} = useArticleSecurity(toRef(props.article))
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
      <CommonSectionMenuItem
        v-if="articleDeliveryStatus"
        :label="__('Message Status')"
      >
        <CommonIcon
          :name="articleDeliveryStatus.icon"
          size="tiny"
          class="inline"
        />
        {{ $t(articleDeliveryStatus.message) }}
      </CommonSectionMenuItem>
      <CommonSectionMenuItem :label="__('Created')">
        <CommonDateTime :date-time="article.createdAt" type="absolute" />
      </CommonSectionMenuItem>
      <CommonSectionMenuItem
        v-if="hasSecurityAttribute"
        :label="__('Security')"
      >
        <div class="flex flex-col gap-1">
          <span v-if="article.securityState?.type">
            {{ translateArticleSecurity(article.securityState.type) }}
          </span>

          <span v-if="isEncrypted">
            <CommonIcon
              class="mb-1 inline"
              size="tiny"
              :name="encryptionIcon"
            />
            {{ $t(encryptedStatusMessage) }}
            <div v-if="encryptionMessage" class="ms-5 break-all">
              {{ $t(encryptionMessage) }}
            </div>
          </span>

          <span v-if="isSigned">
            <CommonIcon class="mb-1 inline" size="tiny" :name="signingIcon" />
            {{ $t(signedStatusMessage) }}
            <div v-if="signingMessage" class="ms-5 break-all">
              {{ $t(signingMessage) }}
            </div>
          </span>
        </div>
      </CommonSectionMenuItem>
    </CommonSectionMenu>
  </CommonDialog>
</template>
