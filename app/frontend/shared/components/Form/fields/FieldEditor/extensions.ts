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
import type { FieldEditorProps } from '#shared/components/Form/fields/FieldEditor/types.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'

import { HtmlCharacterCount } from './extensions/CharacterCount/HtmlCharacterCount.ts'
import { PlainCharacterCount } from './extensions/CharacterCount/PlainCharacterCount.ts'
import { TableKit } from './extensions/TableKit.ts'

import type { Extensions } from '@tiptap/core'
import type { Ref } from 'vue'

export const imageExtensionName = Image.name
export const PlaceholderExtensionName = Placeholder.name

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
