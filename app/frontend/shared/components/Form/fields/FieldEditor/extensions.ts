// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import Blockquote from '@tiptap/extension-blockquote'
import CodeBlockLowlight from '@tiptap/extension-code-block-lowlight'
import Color from '@tiptap/extension-color'
import Paragraph from '@tiptap/extension-paragraph'
import Placeholder from '@tiptap/extension-placeholder'
import { TextStyle } from '@tiptap/extension-text-style'
import StarterKit from '@tiptap/starter-kit'
import { common, createLowlight } from 'lowlight'

import AiAssistantTextTools from '#shared/components/Form/fields/FieldEditor/extensions/AiAssistantTextTools.ts'
import HardBreakPlain from '#shared/components/Form/fields/FieldEditor/extensions/HardBreakPlain.ts'
import Image from '#shared/components/Form/fields/FieldEditor/extensions/Image.ts'
import { IndentExtension } from '#shared/components/Form/fields/FieldEditor/extensions/Indent.ts'
import KnowledgeBaseSuggestion from '#shared/components/Form/fields/FieldEditor/extensions/KnowledgeBaseSuggestion.ts'
import Link from '#shared/components/Form/fields/FieldEditor/extensions/Link.ts'
import { PasteHandler } from '#shared/components/Form/fields/FieldEditor/extensions/PasteHandler.ts'
import Signature from '#shared/components/Form/fields/FieldEditor/extensions/Signature.ts'
import {
  MarginLeft,
  MarginRight,
} from '#shared/components/Form/fields/FieldEditor/extensions/Styles.ts'
import TextModuleSuggestion from '#shared/components/Form/fields/FieldEditor/extensions/TextModuleSuggestion.ts'
import UserMention, {
  UserLink,
} from '#shared/components/Form/fields/FieldEditor/extensions/UserMention.ts'
import VideoEmbed from '#shared/components/Form/fields/FieldEditor/extensions/VideoEmbed.ts'
import { ANSWER_LINK_ACTION_NAME } from '#shared/components/Form/fields/FieldEditor/features/link/answerLink.ts'
import { VIDEO_EMBED_ACTION_NAME } from '#shared/components/Form/fields/FieldEditor/features/video-embed/videoEmbed.ts'
import type {
  EditorCustomExtensions,
  EditorExtensionSet,
  FieldEditorProps,
} from '#shared/components/Form/fields/FieldEditor/types.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'

import { HtmlCharacterCount } from './extensions/CharacterCount/HtmlCharacterCount.ts'
import { PlainCharacterCount } from './extensions/CharacterCount/PlainCharacterCount.ts'
import { TableKit } from './extensions/TableKit.ts'

import type { Extensions } from '@tiptap/core'
import type { Ref } from 'vue'

export const imageExtensionName = Image.name
export const PlaceholderExtensionName = Placeholder.name

/**
 * Editor tools that are off everywhere unless a field opts into them by naming them in its `meta`.
 *
 * Keyed on the tool name, not on a TipTap extension: `knowledgeBaseAnswerLink` is a toolbar action
 * over the existing `link` mark and has no extension of its own. Both the extension list and the
 * toolbar filter go by name, so either kind of tool belongs here.
 */
export const optInExtensionNames = [
  ANSWER_LINK_ACTION_NAME,
  VIDEO_EMBED_ACTION_NAME,
] as const satisfies readonly EditorCustomExtensions[]

/**
 * Names of the extensions and tools a field switches off, in the single array both the extension
 * list and the toolbar are filtered by.
 *
 * A regular tool is on until the field's `meta` switches it off with `disabled: true`. An opt-in
 * tool is the other way around: off until the field declares its key, and off again if that key
 * carries `disabled: true`. The basic set switches every opt-in tool off regardless of `meta`.
 */
export const getDisabledExtensionNames = (
  meta: FieldEditorProps['meta'],
  extensionSet?: EditorExtensionSet,
): (EditorCustomExtensions | string)[] => {
  const disabled = Object.entries(meta || {})
    .filter(([, value]) => value.disabled)
    .map(([key]) => key as EditorCustomExtensions | string)

  const optedOut = optInExtensionNames.filter((name) => extensionSet === 'basic' || !meta?.[name])

  return [...new Set([...disabled, ...optedOut])]
}

export const lowlight = createLowlight(common)

export const getPlainExtensions = (
  placeholder = '',
  meta: FieldEditorProps['meta'],
): Extensions => [
  StarterKit.configure({
    blockquote: false,
    bold: false,
    bulletList: false,
    code: false,
    codeBlock: false,
    dropcursor: false,
    gapcursor: false,
    heading: false,
    horizontalRule: false,
    italic: false,
    listItem: false,
    hardBreak: false,
    orderedList: false,
    strike: false,
    link: {
      openOnClick: false,
      autolink: false,
    },
  }),
  PlainCharacterCount.configure(
    meta?.footer?.maxlength && !meta?.footer?.allowExceedMaxLength
      ? { limit: meta.footer.maxlength }
      : {},
  ),
  HardBreakPlain,
  Placeholder.configure({
    placeholder,
  }),
]

export const getHtmlExtensions = (placeholder = '', meta: FieldEditorProps['meta']): Extensions => [
  StarterKit.configure({
    blockquote: false,
    paragraph: false,
    codeBlock: false,
    link: false,
  }),
  Blockquote.extend({
    addAttributes() {
      return {
        ...this.parent?.(),
        type: {
          default: null,
        },
        'data-marker': {
          default: null,
        },
      }
    },
  }),
  HtmlCharacterCount.configure(
    meta?.footer?.maxlength && !meta?.footer?.allowExceedMaxLength
      ? {
          limit: meta.footer.maxlength,
        }
      : {},
  ),
  // CharacterCount,
  CodeBlockLowlight.configure({ lowlight }),
  Color,
  IndentExtension,
  MarginLeft.configure({
    types: ['listItem', 'taskItem', 'heading', 'paragraph'],
  }),
  MarginRight.configure({
    types: ['listItem', 'taskItem', 'heading', 'paragraph'],
  }),
  Paragraph.extend({
    addAttributes() {
      return {
        ...this.parent?.(),
        'data-marker': {
          default: null,
        },
      }
    },
  }),
  Link,
  TextStyle,
  VideoEmbed,
  UserLink,
  PasteHandler,
  Placeholder.configure({
    placeholder,
  }),
  TableKit.configure({
    table: {
      resizable: true,
      allowTableNodeSelection: true,
    },
  }),
]

export const getCustomExtensions = (
  context: Ref<FormFieldContext<FieldEditorProps>>,
): Extensions => [
  Image,
  Signature,
  UserMention(context),
  KnowledgeBaseSuggestion(context),
  TextModuleSuggestion(context),
  AiAssistantTextTools(context),
]
