// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { TicketById, TicketArticle } from '@shared/entities/ticket/types'
import type { AddressesField } from '@shared/graphql/types'
import type { ConfigList } from '@shared/types/store'
import { uniq } from 'lodash-es'
import type { TicketArticlePerformOptions } from '../types'
import { getArticleSelection, getReplyQuoteHeader } from './selection'

const getEmailAddresses = (field?: Maybe<AddressesField>) => {
  if (!field) return []
  const addresses = field.parsed?.filter(
    (email): email is { emailAddress: string; isSystemAddress: boolean } =>
      !!email.emailAddress,
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
  if (sender === 'Agent') {
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

const prepareEmails = (
  emailsSeen: Set<string>,
  emails: string[],
  newEmail?: string[],
) => {
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
    newArticle.to = prepareEmails(
      emailsSeen,
      getEmailAddresses(article.from),
      newArticle.to,
    )
  }

  if (article.to) {
    newArticle.to = prepareEmails(
      emailsSeen,
      getEmailAddresses(article.to),
      newArticle.to,
    )
  }

  if (article.cc) {
    newArticle.cc = prepareEmails(
      emailsSeen,
      getEmailAddresses(article.cc),
      newArticle.cc,
    )
  }
}

// app/assets/javascripts/app/lib/app_post/utils.coffee:1236
const getRecipientArticle = (
  ticket: TicketById,
  article: TicketArticle,
  all = false,
) => {
  const type = article.type?.name

  if (type === 'phone') {
    return getPhoneArticle(ticket, article)
  }

  const newArticle = getEmptyArticle(article)

  const sender = article.sender?.name

  const senderIsSystem = areAddressesSystem(article.from)
  const recipientIsSystem = areAddressesSystem(article.to)

  const senderEmail = article.createdBy.email
  const isSystem =
    !recipientIsSystem &&
    sender === 'Agent' &&
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

export const replyToEmail = (
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
  let { content: selection, full } = getArticleSelection(
    options.selection,
    article,
    config,
  )

  if (selection) {
    const header = getReplyQuoteHeader(config, article)
    // data-full will be removed by the backend, it's used only for siganture handling
    selection = `<br><blockquote type="cite" ${
      full ? 'data-full="true"' : ''
    }>${header}${selection}</blockquote>`
  }

  const currentBody = options.getNewArticleBody('text/html')
  const body =
    (selection || '') +
    (currentBody && selection ? `<p></p>${currentBody}` : currentBody)

  // signature is handled in article type "onSelected" hook
  options.openReplyDialog({
    ...newArticle,
    subtype: 'reply',
    body,
  })
}
