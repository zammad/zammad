// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { mountComponent } from '#cy/utils.ts'
import { FormKit } from '@formkit/vue'

import Form from '#shared/components/Form/Form.vue'

export const mountEditor = (props: Record<string, unknown> = {}) => {
  return mountComponent(FormKit, {
    props: {
      id: 'editor',
      name: 'editor',
      type: 'editor',
      ...props,
    },
  })
}

export const mountEditorWithAttachments = () => {
  const props = {
    schema: [
      {
        isLayout: true,
        component: 'FormGroup',
        children: [
          {
            name: 'editor',
            type: 'editor',
            props: {
              meta: {
                mentionKnowledgeBase: {
                  attachmentsNodeName: 'attachments',
                },
              },
            },
          },
          {
            name: 'attachments',
            type: 'file',
            props: {
              multiple: true,
            },
          },
        ],
      },
    ],
  }

  return mountComponent(Form, {
    props,
    attrs: {
      class: 'form',
    },
  })
}
