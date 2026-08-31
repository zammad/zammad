// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import {
  EnumKnowledgeBaseAnswerScreen,
  EnumKnowledgeBaseAnswerScreenBehavior,
} from '#shared/graphql/types.ts'

const { StayOnTab, CloseTabAndOpenAnswer, CloseTabAndOpenCategory, CloseTabAndAddAnother } =
  EnumKnowledgeBaseAnswerScreenBehavior

const OPTION_LABEL: Record<EnumKnowledgeBaseAnswerScreenBehavior, string> = {
  [StayOnTab]: __('Stay on tab'),
  [CloseTabAndOpenAnswer]: __('Close tab and open the answer'),
  [CloseTabAndOpenCategory]: __('Close tab and open the category'),
  [CloseTabAndAddAnother]: __('Close tab and add another answer'),
}

// The two screens differ by one option each, and only because that option has nothing to act on in
//   the other:
//
// - `stayOnTab` is edit-only. Its tab holds the answer, so it can stay open on what was just saved;
//   a create tab is keyed on a route that carries no record, and the answer it filed has an edit tab
//   of its own.
// - `closeTabAndAddAnother` is create-only. There is no second answer to add from an edit tab, and
//   this is the option that makes filing a series of answers bearable: the tab closes and a fresh
//   form opens in the same category.
//
// Everything else - the control, the handler, the mutation - is shared, and this list is what a
//   screen can store: a value that is not offered here can never be picked, so neither screen can
//   end up holding the other's.
const SCREEN_OPTIONS: Record<
  EnumKnowledgeBaseAnswerScreen,
  EnumKnowledgeBaseAnswerScreenBehavior[]
> = {
  [EnumKnowledgeBaseAnswerScreen.Create]: [
    CloseTabAndAddAnother,
    CloseTabAndOpenAnswer,
    CloseTabAndOpenCategory,
  ],
  [EnumKnowledgeBaseAnswerScreen.Edit]: [StayOnTab, CloseTabAndOpenAnswer, CloseTabAndOpenCategory],
}

export const behaviorOptions = (screen: EnumKnowledgeBaseAnswerScreen) =>
  SCREEN_OPTIONS[screen].map((key) => ({ key, label: OPTION_LABEL[key] }))

export const behaviorOptionLookup = (screen: EnumKnowledgeBaseAnswerScreen) =>
  behaviorOptions(screen).reduce(
    (acc, option) => {
      acc[option.key] = option
      return acc
    },
    {} as Record<EnumKnowledgeBaseAnswerScreenBehavior, ReturnType<typeof behaviorOptions>[0]>,
  )

// Defaults in code rather than as an admin setting. The ticket counterpart has one
//   (`ticket_secondary_action`), but the story does not ask for a knowledge base equivalent, and it
//   would mean a new setting plus a migration plus an admin UI entry.
//
// One per screen, each what the view did before it had a choice at all: an edit tab stays open on
//   the answer it saved, and a create tab leaves for the answer it filed. Neither is a nudge
//   towards a behavior nobody asked for.
const DEFAULT_BEHAVIOR: Record<
  EnumKnowledgeBaseAnswerScreen,
  EnumKnowledgeBaseAnswerScreenBehavior
> = {
  [EnumKnowledgeBaseAnswerScreen.Create]: CloseTabAndOpenAnswer,
  [EnumKnowledgeBaseAnswerScreen.Edit]: StayOnTab,
}

// A user preference per screen, and never the ticket detail view's `secondaryAction` - the same
//   keys the mutation writes (Gql::Mutations::User::Current::KnowledgeBase::AnswerScreenBehavior).
export const PREFERENCE_KEY: Record<EnumKnowledgeBaseAnswerScreen, string> = {
  [EnumKnowledgeBaseAnswerScreen.Create]: 'knowledgeBaseAnswerCreateSecondaryAction',
  [EnumKnowledgeBaseAnswerScreen.Edit]: 'knowledgeBaseAnswerSecondaryAction',
}

// Read in one place, because the control and the handler have to agree on it - and on what an unset
//   preference means. A stored value this screen does not offer is read as unset: it cannot be
//   picked here, so it is either the other screen's or a leftover, and neither has anything to say
//   about this one.
export const screenBehaviorFromPreferences = (
  screen: EnumKnowledgeBaseAnswerScreen,
  preferences?: Record<string, unknown> | null,
): EnumKnowledgeBaseAnswerScreenBehavior => {
  const stored = preferences?.[
    PREFERENCE_KEY[screen]
  ] as EnumKnowledgeBaseAnswerScreenBehavior | null

  return stored && SCREEN_OPTIONS[screen].includes(stored) ? stored : DEFAULT_BEHAVIOR[screen]
}
