// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, type Ref } from 'vue'

import type { SelectOption } from '#shared/components/CommonSelect/types.ts'
import type { FormRefParameter } from '#shared/components/Form/types.ts'
import { useKeyboardShortcut } from '#shared/composables/useKeyboardShortcut/useKeyboardShortcut.ts'
import type { TicketArticle, TicketById } from '#shared/entities/ticket/types.ts'
import { createArticleActions } from '#shared/entities/ticket-article/action/plugins/index.ts'
import type {
  AppSpecificTicketArticleType,
  TicketArticlePerformOptions,
} from '#shared/entities/ticket-article/action/plugins/types.ts'
import type { TicketArticleTranslation } from '#shared/entities/ticket-article/stores/types.ts'

import { findFocusedFormNode } from '#desktop/composables/useFormSubmitShortcut.ts'
import { useObjectReferenceShortcut } from '#desktop/composables/useObjectReferenceShortcut.ts'
import { useTicketNumber } from '#desktop/entities/ticket/composables/useTicketNumber.ts'

import { useArticleActionPerform } from './useArticleActionPerform.ts'

import type { FormKitNode } from '@formkit/core'

interface TicketDetailViewShortcutsContext {
  ticket: Ref<TicketById | undefined>
  // In the order the article list shows them.
  articles: Ref<TicketArticle[]>
  form: FormRefParameter
  isReady: Ref<boolean>
  isTicketEditable: Ref<boolean>
  newTicketArticlePresent: Ref<boolean | undefined>
  ticketArticleTypes: Ref<AppSpecificTicketArticleType[]>
  articleTranslation: Pick<TicketArticleTranslation, 'isTranslationDisplayed'>
  showArticleForm: (
    articleType: string,
    performReply: AppSpecificTicketArticleType['performReply'],
  ) => void
  openReplyForm: TicketArticlePerformOptions['openReplyForm']
  getNewArticleBody: TicketArticlePerformOptions['getNewArticleBody']
  submit: () => void
  scrollToArticle: (direction: 'next' | 'previous') => void
}

const PENDING_TIME_DEFAULT_DAYS = 3

const waitForFormUpdate = (formNode: FormKitNode) =>
  new Promise<void>((resolve) => {
    const receipt = formNode.on('message-removed', ({ payload }) => {
      if (payload.key !== 'formUpdaterProcessing') return

      formNode.off(receipt)
      resolve()
    })
  })

export const useTicketDetailViewShortcuts = (context: TicketDetailViewShortcutsContext) => {
  const { ticket, articles, form, isReady, isTicketEditable } = context

  const canChangeTicket = computed(() => isReady.value && isTicketEditable.value)

  const changeOptions = { onlyOutsideInputs: true, enabled: canChangeTicket }

  useKeyboardShortcut(
    'open-note-box',
    () => {
      const noteType = context.ticketArticleTypes.value.find((type) => type.value === 'note')
      if (!noteType) return

      // A note being composed keeps its type and with it its internal flag, only the editor
      //   takes the focus.
      context.showArticleForm('note', noteType.performReply)
    },
    changeOptions,
  )

  const { performArticleAction } = useArticleActionPerform(context)

  const findLastReplyAction = (currentTicket: TicketById) => {
    for (const article of articles.value.toReversed()) {
      const disposeCallbacks: (() => unknown)[] = []

      const actions = createArticleActions(currentTicket, article, 'desktop', {
        onDispose: (callback) => disposeCallbacks.push(callback),
        recalculate: () => {},
      })

      disposeCallbacks.forEach((callback) => callback())

      // The reply actions of all channels share the reply icon, which is what the old view looks for.
      const replyAction = actions.find((action) => action.icon === 'reply')
      if (!replyAction) continue

      const replyAllAction = actions.find((action) => action.name === 'email-reply-all')

      return { article, action: replyAllAction ?? replyAction }
    }
  }

  useKeyboardShortcut(
    'reply-to-last-article',
    () => {
      if (!ticket.value) return

      const lastReply = findLastReplyAction(ticket.value)
      if (!lastReply) return

      performArticleAction(lastReply.action, lastReply.article)
    },
    changeOptions,
  )

  useKeyboardShortcut(
    'toggle-article-internal',
    () => {
      if (!context.newTicketArticlePresent.value) return

      const internalNode = form.value?.getNodeByName('internal')
      // Hidden on a ticket the user only sees as its customer, also when they are an agent.
      if (!internalNode || internalNode.context?.disabled || internalNode.props.hidden) return

      // Committed at once, so a press within the debounce of the field flips the flipped value.
      internalNode.input(!internalNode.value, false)
    },
    changeOptions,
  )

  const setDefaultPendingTime = async () => {
    const pendingTimeNode = form.value?.getNodeByName('pending_time')
    if (!pendingTimeNode || pendingTimeNode.value) return

    const pendingTime = new Date()
    pendingTime.setDate(pendingTime.getDate() + PENDING_TIME_DEFAULT_DAYS)

    await form.value?.updateChangedFields({ pending_time: { value: pendingTime.toISOString() } })
  }

  const closeTicket = async (formNode: FormKitNode, stateNode: FormKitNode) => {
    // An update still running may change the states on offer, and the wait below has to end with
    //   the run of the state change, not with that one.
    if (formNode.context?.state.formUpdaterProcessing) await waitForFormUpdate(formNode)

    const closeState = (
      stateNode.props.options as (SelectOption & { defaultClose?: boolean })[] | undefined
    )?.find((option) => option.defaultClose)
    if (!closeState) return

    if (stateNode.value !== closeState.value) {
      // Like the state field, which a core workflow can make read-only.
      if (stateNode.context?.disabled) return

      const formUpdated = waitForFormUpdate(formNode)

      await form.value?.updateChangedFields({ state_id: { value: closeState.value } }, true)
      await formUpdated
      await formNode.settled
    }

    // A pending state needs a time, which the core workflow asks for only once the state is set.
    await setDefaultPendingTime()

    context.submit()
  }

  // A press while the state change is applied would queue a submit of its own.
  let isClosing = false

  useKeyboardShortcut(
    'update-as-closed',
    async () => {
      const formNode = form.value?.formNode
      const stateNode = form.value?.getNodeByName('state_id')

      // Like the update button, which is disabled while an update is being submitted.
      if (!formNode || !stateNode || isClosing || formNode.context?.disabled) return

      isClosing = true

      try {
        await closeTicket(formNode, stateNode)
      } finally {
        isClosing = false
      }
    },
    changeOptions,
  )

  // The update button is no submit button of the form, it checks the form before submitting it.
  useKeyboardShortcut('submit-form', () => context.submit(), {
    enabled: () =>
      canChangeTicket.value &&
      !!form.value &&
      !form.value.formNode.context?.disabled &&
      findFocusedFormNode() === form.value.formNode,
  })

  const { ticketNumberWithTicketHook } = useTicketNumber(ticket)

  useObjectReferenceShortcut(
    () => ({
      number: ticketNumberWithTicketHook.value,
      title: ticket.value?.title,
      path: ticket.value && `/tickets/${ticket.value.internalId}`,
    }),
    { enabled: isReady },
  )

  // Arrow keys belong to whatever has the focus, so the article navigation takes them only from
  //   the page itself.
  const articleNavigationOptions = {
    enabled: () => isReady.value && document.activeElement === document.body,
  }

  useKeyboardShortcut(
    'navigate-articles',
    ({ event }) => context.scrollToArticle(event.key === 'ArrowLeft' ? 'previous' : 'next'),
    articleNavigationOptions,
  )
}
