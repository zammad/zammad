// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import Underline from '@tiptap/extension-underline'
import OrderedList from '@tiptap/extension-ordered-list'
import ListItem from '@tiptap/extension-list-item'
import Link from '@tiptap/extension-link'
import Blockquote from '@tiptap/extension-blockquote'
import StarterKit from '@tiptap/starter-kit'
import CharacterCount from '@tiptap/extension-character-count'

import type { Extensions } from '@tiptap/core'

import type { Ref } from 'vue'
import type { FormFieldContext } from '@shared/components/Form/types/field'
import UserMention, { UserLink } from '../suggestions/UserMention'
import KnowledgeBaseSuggestion from '../suggestions/KnowledgeBaseSuggestion'
import TextModuleSuggestion from '../suggestions/TextModuleSuggestion'
import Image from './Image'
import Signature from './Signature'
import type { FieldEditorProps } from '../types'

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
    orderedList: false,
    strike: false,
  }),
  CharacterCount,
]

export const getHtmlExtensions = (): Extensions => [
  StarterKit.configure({
    orderedList: false,
    listItem: false,
    blockquote: false,
  }),
  CharacterCount,
  Underline,
  OrderedList,
  ListItem,
  Blockquote.extend({
    addAttributes() {
      return {
        ...this.parent?.(),
        type: {
          default: null,
        },
        'data-full': {
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
