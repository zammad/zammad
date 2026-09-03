// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

// The key of an answer edit tab, as Taskbar.entity_key(answer, locale) writes it:
//   'KnowledgeBase__Answer-42-de-de'. Only the id segment is free of '-', so everything past it is
//   the locale.
//
// From the key, not from the entity: both parts are needed before the entity arrives, and the
//   locale is not part of the answer at all.
export const answerTaskbarTabKeyParts = (key?: string) => {
  const [, answerInternalId, ...localeParts] = (key ?? '').split('-')

  if (!answerInternalId || localeParts.length === 0) return undefined

  return { answerInternalId, localeCode: localeParts.join('-') }
}

export const taskbarTabLocaleCode = (key?: string) => answerTaskbarTabKeyParts(key)?.localeCode
