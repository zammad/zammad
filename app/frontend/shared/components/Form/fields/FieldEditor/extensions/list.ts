// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import Underline from '@tiptap/extension-underline'
import OrderedList from '@tiptap/extension-ordered-list'
import ListItem from '@tiptap/extension-list-item'
import Link from '@tiptap/extension-link'
import StarterKit from '@tiptap/starter-kit'

import type { Extensions } from '@tiptap/core'

import type { Ref } from 'vue'
import type { FormFieldContext } from '@shared/components/Form/types/field'
import UserMention, { UserLink } from '../suggestions/UserMention'
import KnowledgeBaseSuggestion from '../suggestions/KnowledgeBaseSuggestion'
import TextModuleSuggestion from '../suggestions/TextModuleSuggestion'
import Image from './Image'
import Signature from './Signature'
import type { FieldEditorProps } from '../types'

export default (
  context: Ref<FormFieldContext<FieldEditorProps>>,
): Extensions => [
  StarterKit.configure({
    orderedList: false,
    listItem: false,
  }),
  Underline,
  OrderedList,
  ListItem,
  Image,
  Signature,
  Link.configure({
    openOnClick: false,
    autolink: false,
  }),
  UserLink,
  UserMention(context),
  KnowledgeBaseSuggestion(context),
  TextModuleSuggestion(context),
]
