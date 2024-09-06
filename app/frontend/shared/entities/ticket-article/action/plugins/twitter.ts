// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { isArray, isObject, uniq } from 'lodash-es'

import type { FieldEditorProps } from '#shared/components/Form/fields/FieldEditor/types.ts'
import type { FormValues } from '#shared/components/Form/types.ts'
import { EnumTicketArticleSenderName } from '#shared/graphql/types.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import type { ConfigList } from '#shared/types/store.ts'
import type { ConfidentTake } from '#shared/types/utils.ts'
import { getInitials } from '#shared/utils/formatter.ts'

import type {
  TicketArticleAction,
  TicketArticleActionPlugin,
  TicketArticleType,
} from './types.ts'

const replyToTwitterComment = ((
  ticket,
  article,
  { openReplyForm, getNewArticleBody },
) => {
  const articleData: FormValues = {
    articleType: 'twitter status',
    inReplyTo: article.messageId,
  }

  const body = getNewArticleBody('text/plain')

  const recipients = article.from ? [article.from.raw] : []

  if (article.to) recipients.push(article.to.raw)

  const recipientsString = uniq(
    recipients.filter((recipient) => {
      recipient = recipient.trim().toLowerCase()
      if (body.toLowerCase().includes(recipient)) return false
      if (recipient === `@${ticket.preferences?.channel_screen_name}`)
        return false
      return true
    }),
  ).join(' ')

  if (body) articleData.body = `${recipientsString} ${body} `
  else articleData.body = `${recipientsString} `

  openReplyForm(articleData)
}) satisfies TicketArticleAction['perform']

const replyToTwitterDm = ((ticket, article, { openReplyForm }) => {
  const sender = article.sender?.name

  let to: string | undefined | null
  if (sender === EnumTicketArticleSenderName.Customer) to = article.from?.raw
  else if (sender === EnumTicketArticleSenderName.Agent) to = article.to?.raw

  if (!to) {
    const autorization = article.author.authorizations?.find(
      (a) => a.provider === 'twitter',
    )
    to = autorization?.username || autorization?.uid
  }

  const articleData: FormValues = {
    articleType: 'twitter direct-message',
    body: '',
    to: to ? [to] : [],
    inReplyTo: article.messageId,
  }

  openReplyForm(articleData)
}) satisfies TicketArticleAction['perform']

const getTwitterInitials = (config: ConfigList) => {
  if (config.ui_ticket_zoom_article_twitter_initials) {
    const { user } = useSessionStore()
    if (user) {
      const { firstname, lastname, email } = user
      return `/${getInitials(firstname, lastname, email)}`
    }
  }
  return null
}

const actionPlugin: TicketArticleActionPlugin = {
  order: 300,

  addActions(ticket, article) {
    const type = article.type?.name

    if (type !== 'twitter status' && type !== 'twitter direct-message')
      return []

    const action: TicketArticleAction = {
      apps: ['mobile', 'desktop'],
      label: __('Reply'),
      name: type,
      icon: 'reply',
      view: {
        agent: ['change'],
      },
      perform(ticket, article, options) {
        if (type === 'twitter status')
          return replyToTwitterComment(ticket, article, options)
        return replyToTwitterDm(ticket, article, options)
      },
    }
    return [action]
  },

  addTypes(ticket, { config }) {
    const descriptionType = ticket.createArticleType?.name

    if (
      descriptionType !== 'twitter status' &&
      descriptionType !== 'twitter direct-message'
    )
      return []

    const type: TicketArticleType = {
      apps: ['mobile', 'desktop'],
      value: descriptionType,
      label: __('Twitter'),
      buttonLabel: __('Add message'),
      icon: 'twitter',
      view: {
        agent: ['change'],
      },
      fields: {
        body: {
          required: true,
        },
        to: {},
      },
      internal: false,
      contentType: 'text/plain',
      updateForm(values) {
        if (!isObject(values.article) || isArray(values.article)) return values
        if (typeof values.article.body === 'string') {
          const initials = getTwitterInitials(config)
          values.article.body += initials ? `\n${initials}` : ''
        }
        return values
      },
    }

    let footer: ConfidentTake<FieldEditorProps, 'meta.footer'> = {}

    if (descriptionType === 'twitter status' && type.fields.body) {
      type.fields.body.validation = 'length:1,280'
      footer = {
        maxlength: 280,
        warningLength: 30,
      }
    } else if (type.fields.to && type.fields.body) {
      type.fields.to.required = true
      type.fields.body.validation = 'length:1,10000'

      footer = {
        maxlength: 10000,
        warningLength: 500,
      }
    }

    const initials = getTwitterInitials(config)

    if (initials) footer.text = initials

    type.editorMeta = {
      footer,
    }

    return [type]
  },
}

export default actionPlugin
