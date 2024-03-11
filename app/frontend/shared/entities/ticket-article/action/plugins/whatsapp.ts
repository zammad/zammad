// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getTicketChannelPlugin } from '#shared/entities/ticket/channel/plugins/index.ts'
import type { TicketById } from '#shared/entities/ticket/types.ts'

import type {
  TicketArticleAction,
  TicketArticleActionPlugin,
  TicketArticleType,
} from './types.ts'

// TODO: Maybe add a more readable object which builds the string for the validation rule.
const WHATSAPP_ALLOWED_FILE_SIZES = `audio,${16 * 1024 * 1024},application,${100 * 1024 * 1024},image,${5 * 1024 * 1024},video,${16 * 1024 * 1024},sticker,${500 * 1024}`
const WHATSAPP_ALLOWED_FILE_TYPES = `audio/aac,audio/mp4,audio/amr,audio/mpeg,audio/ogg,application/*,image/jpeg,image/png,video/mp4,video/3gpp,image/webp`
const WHATSAPP_CAPTIONS = `audio,${0},image/webp,${0}`

const canUseWhatsapp = (ticket: TicketById) => {
  const channelPlugin = getTicketChannelPlugin(ticket.initialChannel)
  const channelAlert = channelPlugin?.channelAlert(ticket)

  return Boolean(channelAlert) && Boolean(channelAlert?.variant !== 'danger')
}

const actionPlugin: TicketArticleActionPlugin = {
  order: 300,

  addActions(ticket, article) {
    const sender = article.sender?.name // Customer || Agent
    const type = article.type?.name // 'whatsapp message'

    if (sender !== 'Customer' || type !== 'whatsapp message') return []
    if (!canUseWhatsapp(ticket)) return []

    const action: TicketArticleAction = {
      apps: ['mobile'],
      label: __('Reply'),
      name: 'whatsapp message',
      icon: 'reply',
      view: {
        agent: ['change'],
      },
      perform(ticket, article, { openReplyDialog }) {
        const articleData = {
          articleType: type,
          inReplyTo: article.messageId,
        }
        openReplyDialog(articleData)
      },
    }

    return [action]
  },

  addTypes(ticket) {
    const descriptionType = ticket.createArticleType?.name

    if (descriptionType !== 'whatsapp message') return []
    if (!canUseWhatsapp(ticket)) return []

    const type: TicketArticleType = {
      apps: ['mobile'],
      value: 'whatsapp message',
      label: __('Whatsapp'),
      icon: 'whatsapp',
      view: {
        agent: ['change'],
      },
      attributes: ['attachments'],
      internal: false,
      contentType: 'text/plain',
      validation: {
        // TODO: add plugin layer for handling of body for the attachments where it's not needed.
        // TODO: use require_one instead of own "content_required" rule (remove validation rule again from code base).
        body: `+content_required:attachments|+caption_length:${WHATSAPP_CAPTIONS}|length:1,4096`,
        attachments: `*file_sizes:${WHATSAPP_ALLOWED_FILE_SIZES}|*file_types:${WHATSAPP_ALLOWED_FILE_TYPES}`,
      },
      options: {
        multipleUploads: false,
      },
      // TODO add better possibility to change props for different fields inside this layer
    }
    return [type]
  },
}

export default actionPlugin
