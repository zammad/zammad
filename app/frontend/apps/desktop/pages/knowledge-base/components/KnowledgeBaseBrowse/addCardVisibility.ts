// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

// How much of an add card has to be on screen before the floating toolbar drops its own shortcut
//   for it. Without a threshold `useElementVisibility` flips as soon as a single pixel intersects,
//   so the shortcut would vanish while the card is still barely peeking in at the bottom.
//
// Shared by the category grid and the answer list, whose cards behave alike - a value of its own
//   per card would make the two shortcuts disappear at different moments.
export const ADD_CARD_VISIBILITY_THRESHOLD = 0.65
