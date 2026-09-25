// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { ConfigList } from '#shared/types/store.ts'
import { getFullname } from '#shared/utils/formatter.ts'

import type { CallerLogEntry, CallerLogMatch } from '../types.ts'

export interface CallerLogStatusDisplay {
  icon: string
  iconClass: string
  labelClass: string
}

const MUTED_COLORS = {
  iconClass: 'text-stone-200 dark:text-neutral-500',
  labelClass: 'text-gray-100 dark:text-neutral-400',
}

// A call in progress colors its icon only; the label stays muted like every finished call.
const CONNECTED_COLORS = {
  iconClass: 'text-green-400',
  labelClass: 'text-gray-100 dark:text-neutral-400',
}

// Ringing is the only status the design takes out of the muted palette completely,
//   and the only one that moves.
const RINGING_COLORS = {
  iconClass: 'text-yellow-500 animate-vibrate motion-reduce:animate-none',
  labelClass: 'text-black! dark:text-white!',
}

// Same mapping as the old caller log, but with sentence-case source strings.
export const getCallerLogStatus = ({
  state,
  comment,
}: Pick<CallerLogEntry, 'state' | 'comment'>): string => {
  switch (state) {
    case 'newCall':
      return __('Ringing…')
    case 'answer':
      return __('Connected')
    case 'hangup':
      switch (comment) {
        case 'cancel':
        case 'noAnswer':
        case 'congestion':
          return __('Not reached')
        case 'busy':
          return __('Busy')
        case 'voicemail':
          return __('Voicemail')
        case 'notFound':
          return __('Does not exist')
        case 'normalClearing':
          return __('Call ended')
        default:
          return comment || ''
      }
    default:
      return comment ? `${state}, ${comment}` : state
  }
}

export const getCallerLogStatusDisplay = ({
  state,
  comment,
  direction,
}: Pick<CallerLogEntry, 'state' | 'comment' | 'direction'>): CallerLogStatusDisplay => {
  if (state === 'newCall')
    return {
      icon: direction === 'in' ? 'telephone-inbound' : 'telephone-outbound',
      ...RINGING_COLORS,
    }

  // normalClearing below shares this icon: the call went the same way, it is just over.
  if (state === 'answer') return { icon: 'telephone-v', ...CONNECTED_COLORS }

  if (state === 'hangup') {
    switch (comment) {
      case 'cancel':
      case 'noAnswer':
      case 'congestion':
        return { icon: 'telephone', ...MUTED_COLORS }
      case 'busy':
        return { icon: 'telephone-x', ...MUTED_COLORS }
      case 'voicemail':
        return { icon: 'mic', ...MUTED_COLORS }
      case 'notFound':
        return { icon: 'x', ...MUTED_COLORS }
      case 'normalClearing':
        return { icon: 'telephone-v', ...MUTED_COLORS }
      default:
        break
    }
  }

  return { icon: 'phone', ...MUTED_COLORS }
}

// Same rule as the old caller log: a call that is not over yet cannot be marked as done
//   while it is younger than a minute, so the checkbox follows the call instead of the click.
export const isCallerLogDoneDisabled = (
  { state, createdAt }: Pick<CallerLogEntry, 'state' | 'createdAt'>,
  now: Date,
): boolean => state !== 'hangup' && now.getTime() - new Date(createdAt).getTime() <= 60_000

export const formatDuration = (seconds?: Maybe<number>): string => {
  if (seconds === null || seconds === undefined) return ''

  const total = Math.max(0, Math.floor(seconds))
  const hours = Math.floor(total / 3600)
  const minutes = Math.floor((total % 3600) / 60)
  const rest = total % 60

  const pad = (value: number) => String(value).padStart(2, '0')

  if (hours > 0) return `${hours}:${pad(minutes)}:${pad(rest)}`

  return `${pad(minutes)}:${pad(rest)}`
}

// A phone-only agent receives the matched user with the name fields but without `fullname`,
//   so the name is put together here the way the backend would have.
export const getCallerLogMatchName = (
  match: CallerLogMatch,
  format: ConfigList['user_name_format'],
) => {
  const { user } = match
  if (!user) return match.comment

  return user.fullname || getFullname(user.firstname, user.lastname, format) || match.comment
}

// Only a match with a name to show counts; the first one stands for the call.
export const getCallerLogNamedMatches = (
  matches: CallerLogMatch[],
  format: ConfigList['user_name_format'],
) => matches.filter((match) => getCallerLogMatchName(match, format))
