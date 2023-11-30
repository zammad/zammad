// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { getTicketSignatureQuery } from '#shared/composables/useTicketSignature.ts'
import type {
  TicketArticle,
  TicketById,
} from '#shared/entities/ticket/types.ts'
import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'
import { textCleanup } from '#shared/utils/helpers.ts'
import { uniq } from 'lodash-es'
import { forwardEmail } from './email/forward.ts'
import { replyToEmail } from './email/reply.ts'
import type {
  TicketArticleAction,
  TicketArticleActionPlugin,
  TicketArticleSelectionOptions,
  TicketArticleType,
} from './types.ts'

const canReplyAll = (article: TicketArticle) => {
  const addresses = [article.to, article.cc]
  if (article.sender?.name === 'Customer') {
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
      type === 'phone' && (sender === 'Customer' || sender === 'Agent')

    if (isEmail || isPhone) {
      actions.push(
        {
          apps: ['mobile'],
          name: 'email-reply',
          view: { agent: ['change'] },
          label: __('Reply'),
          icon: { mobile: 'mobile-reply', desktop: 'desktop-reply' },
          perform: (t, a, o) => replyToEmail(t, a, o, config),
        },
        {
          apps: ['mobile'],
          name: 'email-forward',
          view: { agent: ['change'] },
          label: __('Forward'),
          icon: { mobile: 'mobile-forward', desktop: 'desktop-forward' },
          perform: (t, a, o) => forwardEmail(t, a, o, config),
        },
      )
    }

    if (isEmail && canReplyAll(article)) {
      actions.push({
        apps: ['mobile'],
        name: 'email-reply-all',
        view: { agent: ['change'] },
        label: __('Reply All'),
        icon: { mobile: 'mobile-reply-alt', desktop: 'desktop-reply-alt' },
        perform: (t, a, o) => replyToEmail(t, a, o, config, true),
      })
    }

    return actions
  },

  addTypes(ticket, { config }) {
    if (!ticket.group.emailAddress) return []

    const attributes = new Set([
      'to',
      'cc',
      'subject',
      'subtype',
      'attachments',
      'security',
    ])

    if (!config.ui_ticket_zoom_article_email_subject)
      attributes.delete('subject')

    const type: TicketArticleType = {
      value: 'email',
      label: __('Email'),
      apps: ['mobile'],
      icon: { mobile: 'mobile-mail', desktop: 'desktop-mail' },
      attributes: Array.from(attributes),
      view: { agent: ['change'] },
      validation: {
        to: 'required',
      },
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
    }
    return [type]
  },
}

export default actionPlugin
