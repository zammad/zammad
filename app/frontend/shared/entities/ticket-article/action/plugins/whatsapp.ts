// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { createMessage, type FormKitNode } from '@formkit/core'
import { useFormKitNodeById } from '@formkit/vue'

import type { FileUploaded } from '#shared/components/Form/fields/FieldFile/types.ts'
import {
  FormValidationVisibility,
  type FormRef,
} from '#shared/components/Form/types.ts'
import { getNodeId } from '#shared/components/Form/utils.ts'
import { getTicketChannelPlugin } from '#shared/entities/ticket/channel/plugins/index.ts'
import type { TicketById } from '#shared/entities/ticket/types.ts'
import { EnumTicketArticleSenderName } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import { getAcceptableFileTypesString } from '#shared/utils/files.ts'

import type {
  TicketArticleAction,
  TicketArticleActionPlugin,
  TicketArticleType,
} from './types.ts'

const allowedFiles = [
  {
    label: __('Audio file'),
    types: ['audio/aac', 'audio/mp4', 'audio/amr', 'audio/mpeg', 'audio/ogg'],
    size: 16 * 1024 * 1024,
  },
  {
    label: __('Sticker file'),
    types: ['image/webp'],
    size: 500 * 1024,
  },
  {
    label: __('Image file'),
    types: ['image/jpeg', 'image/png'],
    size: 5 * 1024 * 1024,
  },
  {
    label: __('Video file'),
    types: ['video/mp4', 'video/3gpp'],
    size: 16 * 1024 * 1024,
  },
  {
    label: __('Document file'),
    types: [
      'text/plain',
      'application/pdf',
      'application/vnd.ms-powerpoint',
      'application/msword',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    ],
    size: 100 * 1024 * 1024,
  },
]

const acceptableFileTypes = getAcceptableFileTypesString(allowedFiles)
const canUseWhatsapp = (ticket: TicketById) => {
  const channelPlugin = getTicketChannelPlugin(ticket.initialChannel)
  const channelAlert = channelPlugin?.channelAlert(ticket)

  return Boolean(channelAlert) && Boolean(channelAlert?.variant !== 'danger')
}

const actionPlugin: TicketArticleActionPlugin = {
  order: 300,

  addActions(ticket, article) {
    const sender = article.sender?.name
    const type = article.type?.name // 'whatsapp message'

    if (
      sender !== EnumTicketArticleSenderName.Customer ||
      type !== 'whatsapp message'
    )
      return []
    if (!canUseWhatsapp(ticket)) return []

    const action: TicketArticleAction = {
      apps: ['mobile', 'desktop'],
      label: __('Reply'),
      name: 'whatsapp message',
      icon: 'reply',
      alwaysVisible: true,
      view: {
        agent: ['change'],
      },
      perform(ticket, article, { openReplyForm }) {
        const articleData = {
          articleType: type,
          inReplyTo: article.messageId,
        }
        openReplyForm(articleData)
      },
    }

    return [action]
  },

  addTypes(ticket) {
    const descriptionType = ticket.createArticleType?.name

    if (descriptionType !== 'whatsapp message') return []
    if (!canUseWhatsapp(ticket)) return []

    let attachmentsFieldNode: FormKitNode
    let attachmentsCommitEvent: string
    let bodyCommitEventNode: FormKitNode
    let bodyCommitEventListener: string

    const setBodyNotAllowedMessage = (body: FormKitNode) => {
      body.emit('prop:validationVisibility', FormValidationVisibility.Live)

      body.store.set(
        createMessage({
          key: 'bodyNotAllowedForMediaType',
          blocking: true,
          value: i18n.t(
            'No additional text can be sent with this media type. Please remove the text.',
          ),
          type: 'validation',
          visible: true,
        }),
      )
    }

    const removeBodyNotAllowedMessage = (body: FormKitNode) => {
      body.emit('prop:validationVisibility', FormValidationVisibility.Submit)
      body.store.remove('bodyNotAllowedForMediaType')
    }

    const deRegisterListeners = () => {
      if (attachmentsFieldNode) {
        attachmentsFieldNode.off(attachmentsCommitEvent)
      }

      if (bodyCommitEventNode) {
        bodyCommitEventNode.off(bodyCommitEventListener)
        removeBodyNotAllowedMessage(bodyCommitEventNode)
      }
    }

    const handleAllowedBody = (form?: FormRef) => {
      if (!form) return

      const checkAllowedForFileType = (currentFiles: FileUploaded[]) => {
        const body = form.getNodeByName('body')

        if (!body) return

        bodyCommitEventNode = body

        if (
          currentFiles &&
          currentFiles.length > 0 &&
          currentFiles[0].type &&
          (currentFiles[0].type === 'image/webp' ||
            currentFiles[0].type.startsWith('audio'))
        ) {
          bodyCommitEventListener = bodyCommitEventNode.on(
            'commit',
            ({ payload: newValue }) => {
              if (newValue) {
                setBodyNotAllowedMessage(bodyCommitEventNode)
              } else {
                removeBodyNotAllowedMessage(bodyCommitEventNode)
              }
            },
          )

          if (bodyCommitEventNode.value) {
            setBodyNotAllowedMessage(bodyCommitEventNode)
          }
        } else {
          removeBodyNotAllowedMessage(bodyCommitEventNode)
          bodyCommitEventNode.off(bodyCommitEventListener)
        }
      }

      useFormKitNodeById(getNodeId(form.formId, 'attachments'), (node) => {
        attachmentsFieldNode = node

        // Check if the attachments are already present (e.g. after article type switch).
        if (attachmentsFieldNode.value) {
          checkAllowedForFileType(attachmentsFieldNode.value as FileUploaded[])
        }

        attachmentsCommitEvent = node.on('commit', ({ payload: newValue }) => {
          checkAllowedForFileType(newValue)
        })
      })
    }

    const type: TicketArticleType = {
      apps: ['mobile', 'desktop'],
      value: 'whatsapp message',
      label: __('WhatsApp'),
      buttonLabel: __('Add message'),
      icon: 'whatsapp',
      view: {
        agent: ['change'],
      },
      fields: {
        body: {
          required: false,
          validation: 'require_one:attachments|length:1,4096',
        },
        attachments: {
          validation: 'require_one:body',
          accept: acceptableFileTypes,
          multiple: false,
          allowedFiles,
        },
      },
      internal: false,
      contentType: 'text/plain',
      onDeselected: () => {
        deRegisterListeners()
      },
      onSelected: (ticket, context, form) => handleAllowedBody(form),
      onOpened: (ticket, context, form) => handleAllowedBody(form),
    }
    return [type]
  },
}

export default actionPlugin
