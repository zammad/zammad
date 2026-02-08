// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { uniq } from 'lodash-es'
import { ref } from 'vue'

import { useEmailFileUrls } from '#shared/composables/useEmailFileUrls.ts'
import type { TicketArticle } from '#shared/entities/ticket/types.ts'
import { EnumTicketArticleSenderName } from '#shared/graphql/types.ts'
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

const addSignature = ({ body }: TicketArticleSelectionOptions, position?: number) => {
  // Get signature from form props (set by form updater)
  const { signature } = body

  if (!signature) return body.removeSignature()

  body.addSignature({
    renderedBody: signature.renderedBody,
    internalId: signature.internalId,
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
        label: __('Reply all'),
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
          perform: () => openExternalLink(emailFileUrls.originalFormattingUrl.value as string),
        })
      }

      if (emailFileUrls.rawMessageUrl.value) {
        actions.push({
          apps: ['desktop'],
          name: 'email-download-raw-email',
          view: { agent: ['read'] },
          label: __('Download raw email'),
          icon: 'download',
          perform: () => openExternalLink(emailFileUrls.rawMessageUrl.value as string),
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
        body.removeSignature()
      },
      onOpened(_, { body }) {
        // solve the issue in firefox that the signature is not inserted
        // always reset position if reply is added as a new article
        requestAnimationFrame(() => {
          addSignature({ body }, 1)
        })
      },
      onSelected(_, { body }) {
        // try to dynamically set cursor position, depending on where it was before signature was added
        addSignature({ body })
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
