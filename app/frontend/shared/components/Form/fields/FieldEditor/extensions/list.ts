// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import Underline from '@tiptap/extension-underline'
import OrderedList from '@tiptap/extension-ordered-list'
import ListItem from '@tiptap/extension-list-item'
import Link from '@tiptap/extension-link'
import Blockquote from '@tiptap/extension-blockquote'
import StarterKit from '@tiptap/starter-kit'
import Paragraph from '@tiptap/extension-paragraph'
import HardBreak from '@tiptap/extension-hard-break'
import CharacterCount from '@tiptap/extension-character-count'
import TextDirection from 'tiptap-text-direction'

import type { Extensions } from '@tiptap/core'

import type { Ref } from 'vue'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import UserMention, { UserLink } from '../suggestions/UserMention.ts'
import KnowledgeBaseSuggestion from '../suggestions/KnowledgeBaseSuggestion.ts'
import TextModuleSuggestion from '../suggestions/TextModuleSuggestion.ts'
import Image from './Image.ts'
import HardBreakPlain from './HardBreakPlain.ts'
import Signature from './Signature.ts'
import type { FieldEditorProps } from '../types.ts'

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
  HardBreakPlain,
  CharacterCount,
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
    orderedList: false,
    listItem: false,
    blockquote: false,
    paragraph: false,
    hardBreak: false,
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
  CharacterCount,
  Underline,
  OrderedList,
  ListItem,
  HardBreak,
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
  Link.configure({
    openOnClick: false,
    autolink: false,
  }),
  UserLink,
  TextDirection.configure({
    defaultDirection: document.documentElement.getAttribute('dir') as
      | 'ltr'
      | 'rtl'
      | null,
    types: ['paragraph', 'heading'],
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
]
