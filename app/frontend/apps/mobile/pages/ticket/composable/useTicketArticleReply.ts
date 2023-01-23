// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FormRef } from '@shared/components/Form'
import { useDialog } from '@shared/composables/useDialog'
import type { TicketById } from '@shared/entities/ticket/types'
import type { Ref, ShallowRef } from 'vue'
import { computed, ref } from 'vue'
import { useRoute } from 'vue-router'

interface ReplyDialogOptions {
  updateFormLocation: (location: string) => void
}

export const useTicketArticleReply = (
  ticket: Ref<TicketById | undefined>,
  form: ShallowRef<FormRef | undefined>,
) => {
  const newTicketArticleRequested = ref(false)
  const newTicketArticlePresent = ref(false)

  const articleFormGroupNode = computed(() => {
    if (!newTicketArticlePresent.value && !newTicketArticleRequested.value)
      return undefined

    return form.value?.formNode?.at('article')
  })

  const isArticleFormGroupValid = computed(() => {
    return !!articleFormGroupNode.value?.context?.state.valid
  })

  const articleReplyDialog = useDialog({
    name: 'ticket-article-reply',
    component: () =>
      import(
        '@mobile/pages/ticket/components/TicketDetailView/ArticleReplyDialog.vue'
      ),
    beforeOpen: () => {
      newTicketArticleRequested.value = true
    },
    afterClose: () => {
      newTicketArticleRequested.value = false
    },
  })

  const route = useRoute()

  const openArticleReplyDialog = ({
    updateFormLocation,
  }: ReplyDialogOptions) => {
    if (!ticket.value) return

    articleReplyDialog.open({
      name: articleReplyDialog.name,
      ticket,
      form,
      newTicketArticlePresent,
      articleFormGroupNode,
      updateFormLocation,
      onDone() {
        newTicketArticlePresent.value = true
      },
      onDiscard() {
        newTicketArticlePresent.value = false
      },
      onShowArticleForm() {
        updateFormLocation('[data-ticket-article-reply-form]')
      },
      onHideArticleForm() {
        if (route.name === 'TicketInformationDetails') {
          updateFormLocation('[data-ticket-edit-form]')
          return
        }

        updateFormLocation('body')
      },
    })
  }

  return {
    articleReplyDialog,
    newTicketArticleRequested,
    newTicketArticlePresent,
    articleFormGroupNode,
    isArticleFormGroupValid,
    openArticleReplyDialog,
  }
}
