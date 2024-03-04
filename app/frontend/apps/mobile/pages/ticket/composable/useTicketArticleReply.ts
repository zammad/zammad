// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormRef } from '#shared/components/Form/types.ts'
import { useDialog } from '#shared/composables/useDialog.ts'
import type { TicketById } from '#shared/entities/ticket/types.ts'
import type { Ref, ShallowRef } from 'vue'
import { computed, ref } from 'vue'
import { useRoute } from 'vue-router'

interface ReplyDialogOptions {
  updateFormLocation: (location: string) => void
}

export const useTicketArticleReply = (
  ticket: Ref<TicketById | undefined>,
  form: ShallowRef<FormRef | undefined>,
  needSpaceForSaveBanner: Ref<boolean>,
) => {
  const newTicketArticleRequested = ref(false)
  const newTicketArticlePresent = ref(false)

  const articleFormGroupNode = computed(() => {
    if (!newTicketArticlePresent.value && !newTicketArticleRequested.value)
      return undefined

    return form.value?.getNodeByName('article')
  })

  const isArticleFormGroupValid = computed(() => {
    return !!articleFormGroupNode.value?.context?.state.valid
  })

  const articleReplyDialog = useDialog({
    name: 'ticket-article-reply',
    component: () =>
      import(
        '#mobile/pages/ticket/components/TicketDetailView/ArticleReplyDialog.vue'
      ),
    beforeOpen: () => {
      newTicketArticleRequested.value = true
    },
    afterClose: () => {
      newTicketArticleRequested.value = false
    },
  })

  const rememberArticleFormGroup = () => {
    newTicketArticlePresent.value = true
  }

  const route = useRoute()

  const resetDirtyTicketState = () => {
    const stateId = form.value?.getNodeByName('state_id')
    const isDefaultFollowUpStateSet = form.value?.getNodeByName(
      'isDefaultFollowUpStateSet',
    )

    if (
      !stateId ||
      !isDefaultFollowUpStateSet ||
      !isDefaultFollowUpStateSet.value
    )
      return false

    // If the default follow-up state was set, then we want to reset the state on article discard.
    //   See `app/models/form_updater/updater/ticket/edit.rb` for more info.
    stateId.reset()
    isDefaultFollowUpStateSet.reset()

    return true
  }

  const openArticleReplyDialog = async ({
    updateFormLocation,
  }: ReplyDialogOptions) => {
    if (!ticket.value) return

    return articleReplyDialog.open({
      name: articleReplyDialog.name,
      ticket,
      form,
      needSpaceForSaveBanner,
      newTicketArticlePresent,
      articleFormGroupNode,
      updateFormLocation,
      onDone() {
        rememberArticleFormGroup()
      },
      onDiscard() {
        newTicketArticlePresent.value = false

        resetDirtyTicketState()
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

  const closeArticleReplyDialog = (rememberArticle = false) => {
    if (rememberArticle) rememberArticleFormGroup()

    return articleReplyDialog.close()
  }

  return {
    articleReplyDialog,
    newTicketArticleRequested,
    newTicketArticlePresent,
    articleFormGroupNode,
    isArticleFormGroupValid,
    openArticleReplyDialog,
    closeArticleReplyDialog,
  }
}
