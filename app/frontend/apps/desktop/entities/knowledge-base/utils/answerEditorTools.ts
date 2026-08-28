// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FieldEditorProps } from '#shared/components/Form/fields/FieldEditor/types.ts'

/**
 * Which editor tools an answer is written with, for the `meta` of its body field.
 *
 * The two knowledge base tools are opted into here, since they are off in every other editor (see
 * `optInExtensionNames`). The ones switched off are the ticket-shaped ones: the AI text tools and
 * all three mention plugins key off ticket form nodes, and `mentionKnowledgeBase` inserts an
 * answer's text *into a ticket article*, which is the wrong direction inside an answer. Everything
 * else — formatting, tables, code, colors, images, links — stays.
 *
 * Declared with `satisfies` rather than as a plain object, so that a tool named wrongly is a
 * compile error rather than a key nothing ever reads.
 */
export const ANSWER_EDITOR_TOOLS = {
  knowledgeBaseAnswerLink: { disabled: false },
  videoEmbed: { disabled: false },
  aiAssistantTextTools: { disabled: true },
  mentionKnowledgeBase: { disabled: true },
  mentionUser: { disabled: true },
  mentionText: { disabled: true },
} satisfies FieldEditorProps['meta']
