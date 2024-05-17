// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import Blockquote from '@tiptap/extension-blockquote'
import CharacterCount from '@tiptap/extension-character-count'
import HardBreak from '@tiptap/extension-hard-break'
import Link from '@tiptap/extension-link'
import ListItem from '@tiptap/extension-list-item'
import OrderedList from '@tiptap/extension-ordered-list'
import Paragraph from '@tiptap/extension-paragraph'
import Underline from '@tiptap/extension-underline'
import StarterKit from '@tiptap/starter-kit'
import TextDirection from 'tiptap-text-direction'

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
