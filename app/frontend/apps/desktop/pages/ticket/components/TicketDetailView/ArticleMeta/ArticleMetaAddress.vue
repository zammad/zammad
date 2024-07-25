<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { TicketArticle } from '#shared/entities/ticket/types.ts'
// import { EnumTicketArticleSenderName } from '#shared/graphql/types.ts'

interface Props {
  context: {
    article: TicketArticle
  }
  type?: 'from' | 'to'
}

const props = withDefaults(defineProps<Props>(), {
  type: 'from',
})

// const checkIfSystemUser = (article: TicketArticle) => {
//   return article.from?.parsed === undefined
//     ? false
//     : article.from?.parsed?.some((u) => u.isSystemAddress)
// }
//
// const checkIfAgent = (article: TicketArticle) => {
//   return article.sender?.name === EnumTicketArticleSenderName.Agent
// }

const getEmailAddress = (article: TicketArticle) => {
  // const isSystemUser = checkIfSystemUser(article)
  // const isAgent = checkIfAgent(article)
  // :TODO check if we have to handle system users, agents and sysadmin

  if (props.type === 'from') {
    return article.from?.parsed?.at(0)?.emailAddress
  }

  return article.to?.parsed?.at(0)?.emailAddress
}

const getName = (article: TicketArticle) => {
  // :TODO check if we have to handle system users, agents and sysadmin

  if (props.type === 'from') {
    return article.from?.parsed?.at(0)?.name
  }

  return article.to?.parsed?.at(0)?.name
}

const name = computed(() => getName(props.context.article))

const email = computed(() => getEmailAddress(props.context.article))
</script>

<template>
  <div class="flex gap-2">
    <CommonLabel v-if="name" class="text-black dark:text-white">{{
      $t(name)
    }}</CommonLabel>
    <CommonLabel>{{ `<${email}>` }}</CommonLabel>
  </div>
</template>
