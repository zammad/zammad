// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FormValues } from '@shared/components/Form'
import type { FieldEditorProps } from '@shared/components/Form/fields/FieldEditor/types'
import { useSessionStore } from '@shared/stores/session'
import type { ConfigList } from '@shared/types/store'
import type { ConfidentTake } from '@shared/types/utils'
import { getInitials } from '@shared/utils/formatter'
import { isArray, isObject, uniq } from 'lodash-es'
import type {
  TicketArticleAction,
  TicketArticleActionPlugin,
  TicketArticleType,
} from './types'

const replyToTwitterComment = ((
  ticket,
  article,
  { openReplyDialog, getNewArticleBody },
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

  if (body) articleData.body = `${recipientsString} ${body}&nbsp`
  else articleData.body = `${recipientsString}&nbsp`

  openReplyDialog(articleData)
}) satisfies TicketArticleAction['perform']

const replyToTwitterDm = ((ticket, article, { openReplyDialog }) => {
  const sender = article.sender?.name

  let to: string | undefined | null
  if (sender === 'Customer') to = article.from?.raw
  else if (sender === 'Agent') to = article.to?.raw

  if (!to) {
    const autorization = article.createdBy.authorizations?.find(
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

  openReplyDialog(articleData)
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
      apps: ['mobile'],
      label: __('Reply'),
      name: type,
      icon: { mobile: 'mobile-reply' },
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
      apps: ['mobile'],
      value: descriptionType,
      label: __('Twitter'),
      icon: {
        mobile: 'mobile-twitter',
      },
      view: {
        agent: ['change'],
      },
      attributes: [],
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

    let footer: ConfidentTake<FieldEditorProps, 'meta.footer'>

    if (descriptionType === 'twitter status') {
      footer = {
        maxlength: 280,
        warningLength: 30,
      }
    } else {
      type.attributes = ['to']
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
