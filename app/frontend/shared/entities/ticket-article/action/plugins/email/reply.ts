// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { uniq } from 'lodash-es'
import { effectScope } from 'vue'

import { claimInlineImages } from '#shared/components/Form/fields/FieldEditor/features/image-handler/inlineImageUploads.ts'
import type { TicketById, TicketArticle } from '#shared/entities/ticket/types.ts'
import { useTicketArticleQuotedHeaderLazyQuery } from '#shared/entities/ticket-article/graphql/queries/ticketArticleQuotedHeader.api.ts'
import { EnumTicketArticleSenderName, type AddressesField } from '#shared/graphql/types.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import type { ConfigList } from '#shared/types/store.ts'

import { getArticleSelection, getReplyQuoteHeader } from './selection.ts'

import type { TicketArticlePerformOptions } from '../types.ts'

const getEmailAddresses = (field?: Maybe<AddressesField>) => {
  if (!field) return []
  const addresses = field.parsed?.filter(
    (email): email is { emailAddress: string; isSystemAddress: boolean } => !!email.emailAddress,
  )
  if (addresses?.length) {
    return addresses
      .filter((address) => !address.isSystemAddress)
      .map((address) => address.emailAddress)
  }
  return []
}

const getEmptyArticle = (article: TicketArticle) => ({
  articleType: 'email',
  subtype: 'reply',
  to: [] as string[],
  cc: [] as string[],
  subject: undefined as string | undefined,
  body: '',
  inReplyTo: article.messageId,
})

const getPhoneArticle = (ticket: TicketById, article: TicketArticle) => {
  const newArticle = getEmptyArticle(article)

  const sender = article.sender?.name

  // the article we are replying to is an outbound call
  if (sender === EnumTicketArticleSenderName.Agent) {
    if (article.to?.raw.includes('@')) {
      newArticle.to = getEmailAddresses(article.to)
    }
    // the article we are replying to is an incoming call
  } else if (article.from?.raw.includes('@')) {
    newArticle.to = getEmailAddresses(article.from)
  }
  // if sender is customer but in article.from is no email, try to get
  // customers email via customer user
  if (!newArticle.to.length || newArticle.to.every((r) => !r.includes('@')))
    newArticle.to = ticket.customer.email ? [ticket.customer.email] : []
  return newArticle
}

const areAddressesSystem = (address?: Maybe<AddressesField>) => {
  if (!address?.parsed) return false
  return address.parsed.some((address) => address.isSystemAddress)
}

const prepareEmails = (emailsSeen: Set<string>, emails: string[], newEmail?: string[]) => {
  const filteredEmails = emails
    .map((email) => email.toLowerCase())
    .filter((email) => {
      if (!email || emailsSeen.has(email)) return false
      return true
    })

  if (newEmail) {
    filteredEmails.push(...newEmail)
  }

  filteredEmails.forEach((email) => emailsSeen.add(email))

  // see https://github.com/zammad/zammad/issues/2154
  return uniq(filteredEmails).map((a) => a.replace(/'(\S+@\S+\.\S+)'/, '$1'))
}

const prepareAllEmails = (
  emailsSeen: Set<string>,
  article: TicketArticle,
  newArticle: ReturnType<typeof getEmptyArticle>,
) => {
  if (article.from) {
    newArticle.to = prepareEmails(emailsSeen, getEmailAddresses(article.from), newArticle.to)
  }

  if (article.to) {
    newArticle.to = prepareEmails(emailsSeen, getEmailAddresses(article.to), newArticle.to)
  }

  if (article.cc) {
    newArticle.cc = prepareEmails(emailsSeen, getEmailAddresses(article.cc), newArticle.cc)
  }
}

// app/assets/javascripts/app/lib/app_post/utils.coffee:1236
const getRecipientArticle = (ticket: TicketById, article: TicketArticle, all = false) => {
  const type = article.type?.name

  if (type === 'phone') {
    return getPhoneArticle(ticket, article)
  }

  const newArticle = getEmptyArticle(article)

  const sender = article.sender?.name

  const senderIsSystem = areAddressesSystem(article.from)
  const recipientIsSystem = areAddressesSystem(article.to)

  const senderEmail = article.author.email
  const isSystem =
    !recipientIsSystem &&
    sender === EnumTicketArticleSenderName.Agent &&
    senderEmail &&
    article.from?.parsed?.some((address) =>
      address.emailAddress?.toLowerCase().includes(senderEmail),
    )

  if (senderIsSystem) {
    newArticle.to = getEmailAddresses(article.replyTo || article.to)
  }
  // sender is agent - sent via system
  else if (isSystem) {
    newArticle.to = getEmailAddresses(article.to)
  }
  // sender was regular customer
  else {
    newArticle.to = getEmailAddresses(article.replyTo || article.from)
    if (!newArticle.to.length || newArticle.to.every((r) => !r.includes('@')))
      newArticle.to = senderEmail ? [senderEmail] : []
  }

  const emailsSeen = new Set<string>()

  if (newArticle.to.length) {
    newArticle.to = prepareEmails(emailsSeen, newArticle.to)
  }

  if (!all) {
    return newArticle
  }

  prepareAllEmails(emailsSeen, article, newArticle)

  return newArticle
}

// The citation name follows the configured email sender format and is computed
//   server side, shared with the forwarded quote header. On failure the plain
//   author name serves as fallback. Always asks the server: the header follows
//   settings and user data that change without invalidating a cached result.
//   Runs outside any component, so the query gets a scope of its own.
const fetchQuotableAuthorName = async (article: TicketArticle) => {
  const variables = { articleId: article.id }
  const scope = effectScope(true)
  const quotedHeaderQuery = scope.run(
    () =>
      new QueryHandler(
        useTicketArticleQuotedHeaderLazyQuery(variables, { fetchPolicy: 'no-cache' }),
      ),
  )!

  try {
    const { data } = await quotedHeaderQuery.query({ variables })
    return data?.ticketArticleQuotedHeader?.authorName
  } finally {
    scope.stop()
  }
}

export const replyToEmail = async (
  ticket: TicketById,
  article: TicketArticle,
  options: TicketArticlePerformOptions,
  config: ConfigList,
  all = false,
) => {
  const newArticle = getRecipientArticle(ticket, article, all)

  if (config.ui_ticket_zoom_article_email_subject) {
    newArticle.subject = article.subject || ticket.title
  }

  // eslint-disable-next-line prefer-const
  let { content: selection, full } = getArticleSelection(options.selection, article, config)

  if (selection) {
    claimInlineImages(options.formId, selection)

    const authorName = config.ui_ticket_zoom_article_email_full_quote_header
      ? await fetchQuotableAuthorName(article)
      : undefined
    const header = getReplyQuoteHeader(config, article, authorName)
    // data-full will be removed by the backend, it's used only for siganture handling
    selection = `${full ? '' : '<p><br><br></p>'}<blockquote type="cite" ${
      full ? 'data-marker="signature-before"' : ''
    }>${header}${selection}</blockquote>`
  }

  const currentBody = options.getNewArticleBody('text/html')
  const body =
    (selection || '') + (currentBody && selection ? `<p></p>${currentBody}` : currentBody)

  await options.openReplyForm({
    ...newArticle,
    subtype: 'reply',
    body,
  })
}
