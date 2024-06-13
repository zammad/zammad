// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import Blockquote from '@tiptap/extension-blockquote'
import CharacterCount from '@tiptap/extension-character-count'
import CodeBlockLowlight from '@tiptap/extension-code-block-lowlight'
import Color from '@tiptap/extension-color'
import Link from '@tiptap/extension-link'
import Paragraph from '@tiptap/extension-paragraph'
import Table from '@tiptap/extension-table'
import TableCell from '@tiptap/extension-table-cell'
import TableHeader from '@tiptap/extension-table-header'
import TableRow from '@tiptap/extension-table-row'
import TextStyle from '@tiptap/extension-text-style'
import Underline from '@tiptap/extension-underline'
import StarterKit from '@tiptap/starter-kit'
import { common, createLowlight } from 'lowlight'
import TextDirection from 'tiptap-text-direction'

import { IndentExtension } from '#shared/components/Form/fields/FieldEditor/extensions/Indent.ts'
import {
  MarginLeft,
  MarginRight,
} from '#shared/components/Form/fields/FieldEditor/extensions/Styles.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'

import KnowledgeBaseSuggestion from '../suggestions/KnowledgeBaseSuggestion.ts'
import TextModuleSuggestion from '../suggestions/TextModuleSuggestion.ts'
import UserMention, { UserLink } from '../suggestions/UserMention.ts'

import HardBreakPlain from './HardBreakPlain.ts'
import Image from './Image.ts'
import Signature from './Signature.ts'

import type { FieldEditorProps } from '../types.ts'
import type { Extensions } from '@tiptap/core'
import type { Ref } from 'vue'

export const lowlight = createLowlight(common)

export const getPlainExtensions = (): Extensions => [
  StarterKit.configure({
    blockquote: false,
    bold: false,
    bulletList: false,
    code: false,
    codeBlock: false,
    dropcursor: false,
    gapcursor: false,
    heading: false,
    history: false,
    horizontalRule: false,
    italic: false,
    listItem: false,
    hardBreak: false,
    orderedList: false,
    strike: false,
  }),
  CharacterCount,
  HardBreakPlain,
  TextDirection.configure({
    defaultDirection: document.documentElement.getAttribute('dir') as
      | 'ltr'
      | 'rtl'
      | null,
    types: ['paragraph', 'heading'],
  }),
]

export const getHtmlExtensions = (): Extensions => [
  StarterKit.configure({
    blockquote: false,
    paragraph: false,
    codeBlock: false,
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
  CharacterCount,
  CodeBlockLowlight.configure({ lowlight }),
  Color,
  IndentExtension,
  Link.configure({
    openOnClick: false,
    autolink: false,
  }),
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
  TextDirection.configure({
    defaultDirection: document.documentElement.getAttribute('dir') as
      | 'ltr'
      | 'rtl'
      | null,
    types: ['paragraph', 'heading'],
  }),
  Table.configure({
    resizable: true,
    allowTableNodeSelection: true,
  }),
  TableRow,
  TableHeader,
  TableCell,
  TextStyle,
  Underline,
  UserLink,
]

export const getCustomExtensions = (
  context: Ref<FormFieldContext<FieldEditorProps>>,
): Extensions => [
  Image,
  Signature,
  UserMention(context),
  KnowledgeBaseSuggestion(context),
  TextModuleSuggestion(context),
]
