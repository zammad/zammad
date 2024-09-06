// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { uniq } from 'lodash-es'
import { ref } from 'vue'

import { useEmailFileUrls } from '#shared/composables/useEmailFileUrls.ts'
import { getTicketSignatureQuery } from '#shared/composables/useTicketSignature.ts'
import type {
  TicketArticle,
  TicketById,
} from '#shared/entities/ticket/types.ts'
import { EnumTicketArticleSenderName } from '#shared/graphql/types.ts'
import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'
import { textCleanup } from '#shared/utils/helpers.ts'
import openExternalLink from '#shared/utils/openExternalLink.ts'

import { forwardEmail } from './email/forward.ts'
import { replyToEmail } from './email/reply.ts'

import type {
  TicketFieldsType,
  TicketArticleAction,
  TicketArticleActionPlugin,
  TicketArticleSelectionOptions,
  TicketArticleType,
} from './types.ts'

const canReplyAll = (article: TicketArticle) => {
  const addresses = [article.to, article.cc]
  if (article.sender?.name === EnumTicketArticleSenderName.Customer) {
    addresses.push(article.from)
  }
  const foreignRecipients = addresses
    .flatMap((address) => address?.parsed || [])
    .filter((address) => address.emailAddress && !address.isSystemAddress)
    .map((address) => address.emailAddress)
  return uniq(foreignRecipients).length > 1
}

const addSignature = async (
  ticket: TicketById,
  { body }: TicketArticleSelectionOptions,
  position?: number,
) => {
  const ticketSignature = getTicketSignatureQuery()
  const { data: signature } = await ticketSignature.query({
    variables: {
      groupId: ticket.group.id,
      ticketId: ticket.id,
    },
  })
  const text = signature?.ticketSignature?.renderedBody
  const id = signature?.ticketSignature?.id
  if (!text || !id) {
    body.removeSignature()
    return
  }
  body.addSignature({
    body: textCleanup(text),
    id: getIdFromGraphQLId(id),
    position,
  })
}

const actionPlugin: TicketArticleActionPlugin = {
  order: 200,

  addActions(ticket, article, { config }) {
    if (!ticket.group.emailAddress) return []

    const type = article.type?.name
    const sender = article.sender?.name
    const actions: TicketArticleAction[] = []

    const isEmail = type === 'email' || type === 'web'
    const isPhone =
      type === 'phone' &&
      (sender === EnumTicketArticleSenderName.Customer ||
        sender === EnumTicketArticleSenderName.Agent)

    if (isEmail || isPhone) {
      actions.push(
        {
          apps: ['mobile', 'desktop'],
          name: 'email-reply',
          view: { agent: ['change'] },
          label: __('Reply'),
          icon: 'reply',
          alwaysVisible: true,
          perform: (t, a, o) => replyToEmail(t, a, o, config),
        },
        {
          apps: ['mobile', 'desktop'],
          name: 'email-forward',
          view: { agent: ['change'] },
          label: __('Forward'),
          icon: 'forward',
          perform: (t, a, o) => forwardEmail(t, a, o, config),
        },
      )
    }

    if (isEmail && canReplyAll(article)) {
      actions.push({
        apps: ['mobile', 'desktop'],
        name: 'email-reply-all',
        view: { agent: ['change'] },
        label: __('Reply All'),
        icon: 'reply-alt',
        alwaysVisible: true,
        perform: (t, a, o) => replyToEmail(t, a, o, config, true),
      })
    }

    if (isEmail) {
      const emailFileUrls = useEmailFileUrls(article, ref(ticket.internalId))

      if (emailFileUrls.originalFormattingUrl.value) {
        actions.push({
          apps: ['desktop'],
          name: 'email-download-original-email',
          view: { agent: ['read'] },
          label: __('Download original email'),
          icon: 'download',
          perform: () =>
            openExternalLink(
              emailFileUrls.originalFormattingUrl.value as string,
            ),
        })
      }

      if (emailFileUrls.rawMessageUrl.value) {
        actions.push({
          apps: ['desktop'],
          name: 'email-download-raw-email',
          view: { agent: ['read'] },
          label: __('Download raw email'),
          icon: 'download',
          perform: () =>
            openExternalLink(emailFileUrls.rawMessageUrl.value as string),
        })
      }
    }

    return actions
  },

  addTypes(ticket, { config }) {
    if (!ticket.group.emailAddress) return []

    const fields: Partial<TicketFieldsType> = {
      to: { required: true },
      cc: {},
      subject: {},
      body: {
        required: true,
      },
      subtype: {},
      attachments: {},
      security: {},
    }

    if (!config.ui_ticket_zoom_article_email_subject) delete fields.subject

    const type: TicketArticleType = {
      value: 'email',
      label: __('Email'),
      buttonLabel: __('Add email'),
      apps: ['mobile', 'desktop'],
      icon: 'mail',
      view: { agent: ['change'] },
      fields,
      onDeselected(_, { body }) {
        getTicketSignatureQuery().cancel()
        body.removeSignature()
      },
      onOpened(_, { body }) {
        // always reset position if reply is added as a new article
        return addSignature(ticket, { body }, 1)
      },
      onSelected(_, { body }) {
        // try to dynamically set cursor position, dependeing on where it was before signature was added
        return addSignature(ticket, { body })
      },
      internal: false,
      performReply(ticket) {
        return {
          subtype: 'reply',
          to: ticket.customer.email ? [ticket.customer.email] : [],
        }
      },
    }
    return [type]
  },
}

export default actionPlugin
