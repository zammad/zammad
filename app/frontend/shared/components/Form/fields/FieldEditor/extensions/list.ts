// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import Underline from '@tiptap/extension-underline'
import OrderedList from '@tiptap/extension-ordered-list'
import ListItem from '@tiptap/extension-list-item'
import Link from '@tiptap/extension-link'
import StarterKit from '@tiptap/starter-kit'

import type { Extension } from '@tiptap/core'

import UserMention, { UserLink } from '../suggestions/UserMention'
import KnowledgeBaseSuggestion from '../suggestions/KnowledgeBaseSuggestion'
import TextModuleSuggestion from '../suggestions/TextModuleSuggestion'
import Image from './Image'

export default <Extension[]>[
  StarterKit.configure({
    orderedList: false,
    listItem: false,
  }),
  Underline,
  OrderedList,
  ListItem,
  Image,
  Link.configure({
    openOnClick: false,
    autolink: false,
  }),
  UserLink,
  UserMention,
  KnowledgeBaseSuggestion,
  TextModuleSuggestion,
]
