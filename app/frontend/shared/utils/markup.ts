// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { escape } from 'lodash-es'

// to be compatible with app/assets/javascripts/app/lib/app_post/i18n.coffee:267
export const markup = (source: string): string =>
  escape(source)
    .replace(/\|\|(.+?)\|\|/gm, '<i>$1</i>')
    .replace(/\|(.+?)\|/gm, '<b>$1</b>')
    .replace(/_(.+?)_/gm, '<u>$1</u>')
    .replace(/\/\/(.+?)\/\//gm, '<del>$1</del>')
    .replace(/§(.+?)§/gm, '<kbd>$1</kbd>')
    .replace(/\[(.+?)\]\((.+?)\)/gm, '<a href="$2" target="_blank">$1</a>')

export const cleanupMarkup = (source: string): string =>
  source
    .replace(/\|\|(.+?)\|\|/gm, '$1')
    .replace(/\|(.+?)\|/gm, '$1')
    .replace(/_(.+?)_/gm, '$1')
    .replace(/\/\/(.+?)\/\//gm, '$1')
    .replace(/§(.+?)§/gm, '$1')
    .replace(/\[(.+?)\]\((.+?)\)/gm, '$1')
