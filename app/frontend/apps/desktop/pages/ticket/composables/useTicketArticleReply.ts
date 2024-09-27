// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed, ref } from 'vue'

import type { FormRef } from '#shared/components/Form/types.ts'

import type { Ref, ShallowRef } from 'vue'

export const useTicketArticleReply = (
  form: ShallowRef<FormRef | undefined>,
  initialNewTicketArticlePresent: Ref<boolean | undefined>,
) => {
  const localNewTicketArticlePresent = ref<boolean>()
  // TODO: switching tabs when you added a new article is shortly showing the buttons (because taskbar tab don't has the information yet?)
  const newTicketArticlePresent = computed({
    get: () => {
      if (localNewTicketArticlePresent.value !== undefined)
        return localNewTicketArticlePresent.value

      return initialNewTicketArticlePresent.value
    },
    set: (value) => {
      localNewTicketArticlePresent.value = value
    },
  })

  const articleFormGroupNode = computed(() => {
    if (!newTicketArticlePresent.value) return undefined

    return form.value?.getNodeByName('article')
  })

  const isArticleFormGroupValid = computed(() => {
    return !!articleFormGroupNode.value?.context?.state.valid
  })

  const showTicketArticleReplyForm = () => {
    newTicketArticlePresent.value = true
  }

  return {
    newTicketArticlePresent,
    articleFormGroupNode,
    isArticleFormGroupValid,
    showTicketArticleReplyForm,
  }
}
