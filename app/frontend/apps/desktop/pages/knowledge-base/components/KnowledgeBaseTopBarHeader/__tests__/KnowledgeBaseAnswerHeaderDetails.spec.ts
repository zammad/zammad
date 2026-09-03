// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor, within } from '@testing-library/vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import type { BadgeVariant } from '#shared/components/CommonBadge/types.ts'
import { useReactiveNow } from '#shared/composables/useReactiveNow.ts'
import {
  EnumKnowledgeBaseSchedulableVisibility,
  EnumKnowledgeBaseVisibility,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { i18n } from '#shared/i18n.ts'
import { getBadgeClasses } from '#shared/initializer/initializeBadgeClasses.ts'

import KnowledgeBaseAnswerHeaderDetails from '../KnowledgeBaseAnswerHeaderDetails.vue'

import type { KnowledgeBaseAnswerHeader } from '../../../types.ts'

const CURRENT_USER_ID = convertToGraphQLId('User', 1)

// A date still ahead of the moment the test runs, which is what a scheduled change looks like on
//   the record: the same three columns, only not reached yet.
//
// The extra hour keeps each of them clear of the boundary the relative formatter floors at -
//   exactly two days from now comes out as "in 1 day" by the time the assertion runs.
const hour = 60 * 60 * 1000
const inDays = (days: number) => new Date(Date.now() + days * 24 * hour + hour).toISOString()
const OTHER_USER_ID = convertToGraphQLId('User', 2)

// The clock both the reached dates and the scheduled change are read against. Driven by hand
//   instead of waited out: the real one is a module-level `useNow` whose interval is registered when
//   the composable is first imported, so fake timers installed in a `beforeEach` never reach it.
//
// The ref is created inside the factory and taken back out by calling the mock, rather than closed
//   over from here: `#shared/i18n` calls this composable while the imports are still being
//   evaluated, which is before any `const` of this file exists.
vi.mock('#shared/composables/useReactiveNow.ts', async () => {
  const { ref } = await import('vue')
  const now = ref(new Date())

  return { useReactiveNow: () => now }
})

const reactiveNow = useReactiveNow()

beforeEach(() => {
  reactiveNow.value = new Date()
})

const schedule = (visibility: EnumKnowledgeBaseSchedulableVisibility, scheduledAt: string) => ({
  __typename: 'KnowledgeBaseAnswerVisibilitySchedule' as const,
  visibility,
  scheduledAt,
})

const badgeClasses = getBadgeClasses()

// Every badge of the strip shares the `common-badge` test id, and the scheduled one carries no text
//   the visibility badge could not also carry - so it is found by the one thing that is unique to
//   it: the timestamp of the change it announces.
//
// Which is on the element because the badge asks `CommonDateTime` for `type="relative"` outright,
//   the way the reached-date badges do - so the `datetime` attribute does not depend on the
//   instance's `pretty_date_format`, and a badge without one would be the bug this looks for.
const badgeFor = (view: ReturnType<typeof renderDetails>, scheduledAt: string) =>
  view.container
    .querySelector(`[datetime="${scheduledAt}"]`)
    ?.closest<HTMLElement>('[data-test-id="common-badge"]') ?? null

type AnswerOverrides = Omit<Partial<KnowledgeBaseAnswerHeader>, 'translation'> & {
  translation?: Partial<NonNullable<KnowledgeBaseAnswerHeader['translation']>> | null
}

const answer = ({ translation, ...overrides }: AnswerOverrides = {}): KnowledgeBaseAnswerHeader =>
  ({
    id: convertToGraphQLId('KnowledgeBase::Answer', 1),
    visibility: EnumKnowledgeBaseVisibility.Published,
    internalAt: null,
    publishedAt: null,
    archivedAt: null,
    visibilitySchedules: null,
    category: { id: convertToGraphQLId('KnowledgeBase::Category', 1), breadcrumb: [] },
    // Spread apart from the rest, so an example states only the part of the translation it is about.
    translation:
      translation === null
        ? null
        : {
            id: convertToGraphQLId('KnowledgeBase::Answer::Translation', 1),
            title: 'Some Answer',
            editedAt: null,
            editedBy: null,
            ...translation,
          },
    ...overrides,
  }) as KnowledgeBaseAnswerHeader

const renderDetails = (overrides: AnswerOverrides = {}) =>
  renderComponent(KnowledgeBaseAnswerHeaderDetails, {
    props: { answer: answer(overrides) },
    store: true,
    router: true,
  })

describe('KnowledgeBaseAnswerHeaderDetails', () => {
  it.each([
    [EnumKnowledgeBaseVisibility.Draft, 'Draft'],
    [EnumKnowledgeBaseVisibility.Internal, 'Internal'],
    [EnumKnowledgeBaseVisibility.Published, 'Published'],
    [EnumKnowledgeBaseVisibility.Archived, 'Archived'],
  ])('labels the %s visibility badge', (visibility, label) => {
    const view = renderDetails({ visibility })

    expect(view.getByText(label)).toBeInTheDocument()
  })

  // The badge names the state the *reached* dates put the answer in, not the `visibility` field:
  //   the server derives that one once per request, so it keeps naming the state the answer was in
  //   when the page loaded.
  describe('visibility derived from the reached dates', () => {
    // The first badge of the strip by construction: the visibility badge is the only one the
    //   template renders unconditionally, and it heads the strip.
    const visibilityBadgeOf = (view: ReturnType<typeof renderDetails>) =>
      view.getAllByTestId('common-badge')[0]

    const classesOf = (variant: BadgeVariant) => badgeClasses[variant].split(/\s+/).filter(Boolean)

    // The regression: an answer left open past its scheduled archival used to keep a green
    //   "PUBLISHED" badge while the tooltip beside it had already advanced to the archival date,
    //   and the scheduled badge announcing that archival had already dropped off the strip.
    it('renames the badge once a scheduled archive falls due', async () => {
      const publishedAt = '2026-08-01T10:00:00Z'
      const archivedAt = inDays(1)

      const view = renderDetails({
        visibility: EnumKnowledgeBaseVisibility.Published,
        publishedAt,
        archivedAt,
        visibilitySchedules: [
          schedule(EnumKnowledgeBaseSchedulableVisibility.Archived, archivedAt),
        ],
      })

      expect(within(visibilityBadgeOf(view)).getByText('Published')).toBeInTheDocument()
      expect(visibilityBadgeOf(view)).toHaveClass(...classesOf('success'))
      expect(badgeFor(view, archivedAt)).not.toBeNull()

      reactiveNow.value = new Date(inDays(2))
      await waitForNextTick()

      // The state, its color and the date it is stamped with, all three moved together - and the
      //   change is no longer announced as scheduled, because it has happened.
      expect(within(visibilityBadgeOf(view)).getByText('Archived')).toBeInTheDocument()
      expect(visibilityBadgeOf(view)).toHaveClass(...classesOf('tertiary'))
      expect(visibilityBadgeOf(view)).toHaveAttribute('aria-description', i18n.dateTime(archivedAt))
      expect(badgeFor(view, archivedAt)).toBeNull()
    })

    // The publication of a draft, which is the same move one rung earlier: nothing is reached
    //   before it falls due, so the badge starts on the field it was handed.
    it('renames a draft the moment it is published', async () => {
      const publishedAt = inDays(1)

      const view = renderDetails({
        visibility: EnumKnowledgeBaseVisibility.Draft,
        publishedAt,
        visibilitySchedules: [
          schedule(EnumKnowledgeBaseSchedulableVisibility.Published, publishedAt),
        ],
      })

      expect(within(visibilityBadgeOf(view)).getByText('Draft')).toBeInTheDocument()

      reactiveNow.value = new Date(inDays(2))
      await waitForNextTick()

      expect(within(visibilityBadgeOf(view)).getByText('Published')).toBeInTheDocument()
    })

    // What the create header hands this component: the visibility being picked in the form, with no
    //   stored answer and therefore no dates behind it. The field has to keep naming the badge
    //   there, or every draft-in-progress would read "DRAFT" whatever the form says.
    it.each([
      [EnumKnowledgeBaseVisibility.Internal, 'Internal'],
      [EnumKnowledgeBaseVisibility.Published, 'Published'],
      [EnumKnowledgeBaseVisibility.Archived, 'Archived'],
    ])('falls back to the %s it is handed when no date is reached', (visibility, label) => {
      const view = renderDetails({
        visibility,
        internalAt: null,
        publishedAt: null,
        archivedAt: null,
      })

      expect(within(visibilityBadgeOf(view)).getByText(label)).toBeInTheDocument()
    })

    // A date still ahead is a scheduled change, not history - so it may not rename the badge any
    //   more than it may date it.
    it('leaves the badge alone for a date that is still ahead', () => {
      const view = renderDetails({
        visibility: EnumKnowledgeBaseVisibility.Draft,
        publishedAt: inDays(7),
      })

      expect(within(visibilityBadgeOf(view)).getByText('Draft')).toBeInTheDocument()
    })
  })

  // The strip carries no badge per reached date any more: the answer's own history sits in a
  //   tooltip on the visibility badge, saying when the state that badge names was reached.
  describe('reached date tooltip', () => {
    const INTERNAL_AT = '2026-07-01T10:00:00Z'
    const PUBLISHED_AT = '2026-08-01T10:00:00Z'
    const ARCHIVED_AT = '2026-08-05T10:00:00Z'

    // The first badge of the strip by construction: the visibility badge is the only one the
    //   template renders unconditionally, and it heads the strip.
    const visibilityBadgeOf = (view: ReturnType<typeof renderDetails>) =>
      view.getAllByTestId('common-badge')[0]

    // `aria-description`, which is where the `supportive` modifier puts the message - the badge
    //   names its state in its own text, and a plain tooltip would replace that accessible name
    //   with the bare timestamp.
    const tooltipOf = (view: ReturnType<typeof renderDetails>) =>
      visibilityBadgeOf(view).getAttribute('aria-description')

    // The timestamp alone, the way the edit chip renders its own: the badge it hangs on already
    //   says which state this is the date of.
    it.each([
      [EnumKnowledgeBaseVisibility.Internal, { internalAt: INTERNAL_AT }, INTERNAL_AT],
      [EnumKnowledgeBaseVisibility.Published, { publishedAt: PUBLISHED_AT }, PUBLISHED_AT],
      [EnumKnowledgeBaseVisibility.Archived, { archivedAt: ARCHIVED_AT }, ARCHIVED_AT],
    ])('says when a %s answer reached its state', (visibility, dates, reachedAt) => {
      const view = renderDetails({ visibility, ...dates })

      expect(tooltipOf(view)).toBe(i18n.dateTime(reachedAt))
    })

    // The order of the state machine (internalAt < publishedAt < archivedAt) rather than the
    //   order of the fields: an answer that has been internal, then published, then archived
    //   carries all three dates, and only the last of them is the state it is in now.
    it('dates the last state the answer has reached', () => {
      const view = renderDetails({
        visibility: EnumKnowledgeBaseVisibility.Archived,
        internalAt: INTERNAL_AT,
        publishedAt: PUBLISHED_AT,
        archivedAt: ARCHIVED_AT,
      })

      expect(tooltipOf(view)).toBe(i18n.dateTime(ARCHIVED_AT))
    })

    // A publication state is stored as the date it is reached at, so a date still ahead is a
    //   *scheduled* change. The tooltip says what the answer is - what it is going to become
    //   belongs to the scheduled badge beside it, and to nobody who may not edit the answer.
    it('ignores a date the answer has not reached yet', () => {
      const view = renderDetails({
        internalAt: INTERNAL_AT,
        publishedAt: PUBLISHED_AT,
        archivedAt: inDays(21),
      })

      expect(tooltipOf(view)).toBe(i18n.dateTime(PUBLISHED_AT))
    })

    // A draft stores no date of its own, so it has no timestamp label either - and its
    //   publication date, if it has one, is by definition still ahead.
    it('offers no tooltip for a draft', () => {
      const view = renderDetails({
        visibility: EnumKnowledgeBaseVisibility.Draft,
        publishedAt: inDays(7),
      })

      expect(view.getByText('Draft')).toBeInTheDocument()
      expect(visibilityBadgeOf(view)).not.toHaveAttribute('aria-description')
    })

    it('offers no tooltip before any date is reached', () => {
      const view = renderDetails()

      expect(visibilityBadgeOf(view)).not.toHaveAttribute('aria-description')
    })

    // What a user without knowledge base permission receives: the backend nulls the internal
    //   lifecycle, leaving the badge and the publication date - which it only ever has reached.
    it('dates the publication for a public reader', () => {
      const view = renderDetails({
        publishedAt: PUBLISHED_AT,
        internalAt: null,
        archivedAt: null,
        translation: { editedAt: null, editedBy: null },
      })

      expect(tooltipOf(view)).toBe(i18n.dateTime(PUBLISHED_AT))
      expect(view.queryByText(/edited/)).not.toBeInTheDocument()
    })

    // The tooltip ticks on the clock the scheduled badge does, so a page left open past a due
    //   date stops dating a state the answer has already left behind.
    it('advances to a date the moment it falls due', async () => {
      const archivedAt = inDays(1)

      const view = renderDetails({ publishedAt: PUBLISHED_AT, archivedAt })

      expect(tooltipOf(view)).toBe(i18n.dateTime(PUBLISHED_AT))

      reactiveNow.value = new Date(inDays(2))
      await waitForNextTick()

      expect(tooltipOf(view)).toBe(i18n.dateTime(archivedAt))
    })
  })

  it('renders no edit chip without an edit date', () => {
    const view = renderDetails()

    expect(view.queryByText(/edited/)).not.toBeInTheDocument()
  })

  it('names the editor of the answer translation', () => {
    const view = renderDetails({
      translation: {
        editedAt: '2026-08-01T10:00:00Z',
        editedBy: {
          __typename: 'User',
          id: OTHER_USER_ID,
          firstname: 'Erika',
          lastname: 'Mustermann',
          fullname: 'Erika Mustermann',
        },
      },
    })

    expect(view.getByText(/edited .* by Erika Mustermann/)).toBeInTheDocument()
  })

  it('addresses the current user as "me"', () => {
    mockUserCurrent({ id: CURRENT_USER_ID })

    const view = renderDetails({
      translation: {
        editedAt: '2026-08-01T10:00:00Z',
        editedBy: {
          __typename: 'User',
          id: CURRENT_USER_ID,
          firstname: 'Nicole',
          lastname: 'Braun',
          fullname: 'Nicole Braun',
        },
      },
    })

    expect(view.getByText(/edited .* by me/)).toBeInTheDocument()
  })

  it('falls back to the bare date when the editor is not disclosed', () => {
    const view = renderDetails({
      translation: { editedAt: '2026-08-01T10:00:00Z', editedBy: null },
    })

    expect(view.getByText(/^edited /)).toBeInTheDocument()
    expect(view.queryByText(/ by /)).not.toBeInTheDocument()
  })

  describe('next scheduled visibility', () => {
    // Both negative cases pin the whole strip rather than the absence of one label: the fixture
    //   leaves a bare draft with no dates, no warning and no editor, so the visibility badge is the
    //   only badge there is - and a scheduled badge under any label would break the count.
    //
    // Denied rather than emptied for whoever may not edit the answer, so the field's absence is the
    //   permission check - this component makes none of its own.
    it('renders no badge for a user who may not edit the answer', () => {
      const view = renderDetails({
        visibility: EnumKnowledgeBaseVisibility.Draft,
        visibilitySchedules: null,
      })

      expect(view.queryAllByTestId('common-badge')).toHaveLength(1)
      expect(view.getByText('Draft')).toBeInTheDocument()
    })

    // An editor being told that nothing is scheduled, which is not a badge either.
    it('renders no badge for an editor with nothing scheduled', () => {
      const view = renderDetails({
        visibility: EnumKnowledgeBaseVisibility.Draft,
        visibilitySchedules: [],
      })

      expect(view.queryAllByTestId('common-badge')).toHaveLength(1)
      expect(view.getByText('Draft')).toBeInTheDocument()
    })

    it('names the scheduled state and when it takes effect', () => {
      const scheduledAt = inDays(3)

      const view = renderDetails({
        visibility: EnumKnowledgeBaseVisibility.Draft,
        visibilitySchedules: [
          schedule(EnumKnowledgeBaseSchedulableVisibility.Internal, scheduledAt),
        ],
      })

      const badge = badgeFor(view, scheduledAt)

      expect(badge).not.toBeNull()
      expect(within(badge!).getByText('Internal')).toBeInTheDocument()
      // The answer is still a draft - the badge says what it is going to become, and the visibility
      //   badge at the head of the strip keeps saying what it is.
      expect(view.getByText('Draft')).toBeInTheDocument()
    })

    // `badgeVariants` is shared with the visibility badge, so a scheduled state is tinted exactly as
    //   it will be once it arrives: internal blue, published green, archived grey.
    it.each([
      [EnumKnowledgeBaseSchedulableVisibility.Internal, 'Internal', 'info'],
      [EnumKnowledgeBaseSchedulableVisibility.Published, 'Published', 'success'],
      [EnumKnowledgeBaseSchedulableVisibility.Archived, 'Archived', 'tertiary'],
    ])('colours the badge for a scheduled %s', (visibility, label, variant) => {
      const scheduledAt = inDays(3)

      const view = renderDetails({
        visibility: EnumKnowledgeBaseVisibility.Draft,
        visibilitySchedules: [schedule(visibility, scheduledAt)],
      })

      const badge = badgeFor(view, scheduledAt)

      expect(badge).not.toBeNull()
      expect(within(badge!).getByText(label)).toBeInTheDocument()
      // The variant, not the rendered hue: `initializeGlobalComponentStyles` does not run under
      //   Vitest, so this is the placeholder map - which is the one `CommonBadge` reads too.
      expect(badge).toHaveClass(
        ...badgeClasses[variant as BadgeVariant].split(/\s+/).filter(Boolean),
      )
    })

    // "In case of multiple scheduled visibilities, only the next one scheduled is shown" - the rest
    //   are the sidebar's list, and the popover that will hang off this badge.
    it('announces only the next of several scheduled changes', () => {
      const next = inDays(2)
      const later = inDays(9)

      const view = renderDetails({
        visibility: EnumKnowledgeBaseVisibility.Draft,
        visibilitySchedules: [
          schedule(EnumKnowledgeBaseSchedulableVisibility.Internal, next),
          schedule(EnumKnowledgeBaseSchedulableVisibility.Published, later),
        ],
      })

      expect(badgeFor(view, next)).not.toBeNull()
      expect(badgeFor(view, later)).toBeNull()
      expect(view.queryByText('Published')).not.toBeInTheDocument()
    })

    // The badge ticks on the clock its neighbours do, so a page left open past a due date corrects
    //   itself: the change stops being scheduled here at the moment it becomes a reached date.
    it('drops the badge once the schedule falls due', async () => {
      const scheduledAt = inDays(1)

      const view = renderDetails({
        visibility: EnumKnowledgeBaseVisibility.Draft,
        visibilitySchedules: [
          schedule(EnumKnowledgeBaseSchedulableVisibility.Internal, scheduledAt),
        ],
      })

      expect(badgeFor(view, scheduledAt)).not.toBeNull()

      reactiveNow.value = new Date(inDays(2))
      await waitForNextTick()

      expect(badgeFor(view, scheduledAt)).toBeNull()
    })

    // Both halves of the same three columns at once: a publication the answer has reached, and an
    //   archival still ahead of it.
    it('leaves the reached date the visibility badge carries alone', () => {
      const publishedAt = '2026-08-01T10:00:00Z'
      const scheduledAt = inDays(5)

      const view = renderDetails({
        publishedAt,
        archivedAt: scheduledAt,
        visibilitySchedules: [
          schedule(EnumKnowledgeBaseSchedulableVisibility.Archived, scheduledAt),
        ],
      })

      // Two badges, no more: the visibility badge and the scheduled one. The reached publication
      //   is a tooltip on the first of them rather than a badge of its own.
      expect(view.getAllByTestId('common-badge')).toHaveLength(2)
      expect(view.getAllByTestId('common-badge')[0]).toHaveAttribute(
        'aria-description',
        i18n.dateTime(publishedAt),
      )
      // Once: the scheduled badge only - the archival date has not been reached.
      expect(view.getAllByText('Archived')).toHaveLength(1)
      expect(badgeFor(view, scheduledAt)).not.toBeNull()
    })
  })

  // The badge announces the next change; the popover on it is where the rest of them are reachable.
  describe('scheduled visibility popover', () => {
    const threeSchedules = [
      schedule(EnumKnowledgeBaseSchedulableVisibility.Internal, inDays(2)),
      schedule(EnumKnowledgeBaseSchedulableVisibility.Published, inDays(8)),
      schedule(EnumKnowledgeBaseSchedulableVisibility.Archived, inDays(31)),
    ]

    const renderWithSchedules = () =>
      renderDetails({
        visibility: EnumKnowledgeBaseVisibility.Draft,
        visibilitySchedules: threeSchedules,
      })

    // Matched on the prefix, so the exact relative wording stays the business of the name test
    //   below rather than of every case that needs the trigger.
    const triggerOf = (view: ReturnType<typeof renderDetails>) =>
      view.getByRole('button', { name: /^Scheduled visibility:/ })

    // `role="button"` makes the trigger's children presentational, so the badge's own text is gone
    //   from the accessibility tree - the name has to carry the state and its timing itself, or a
    //   screen reader user would have to open the popover to learn what a sighted user reads.
    it('announces the change the badge shows', () => {
      const view = renderWithSchedules()

      expect(
        view.getByRole('button', { name: 'Scheduled visibility: Internal in 2 days' }),
      ).toBeInTheDocument()
    })

    it('lists every scheduled change on hover, not only the one on the badge', async () => {
      const view = renderWithSchedules()

      await view.events.hover(triggerOf(view))

      const popover = await view.findByRole('region')

      // All three, where the badge shows the first alone.
      expect(within(popover).getAllByRole('listitem')).toHaveLength(3)
      expect(within(popover).getByText('Internal')).toBeInTheDocument()
      expect(within(popover).getByText('Published')).toBeInTheDocument()
      expect(within(popover).getByText('Archived')).toBeInTheDocument()
    })

    it('says when each of them happens', async () => {
      const view = renderWithSchedules()

      await view.events.hover(triggerOf(view))

      const popover = await view.findByRole('region')

      expect(within(popover).getByText('Scheduled visibility')).toBeInTheDocument()
      expect(within(popover).getByText('in 2 days')).toBeInTheDocument()
      expect(within(popover).getByText('in 1 week')).toBeInTheDocument()
      expect(within(popover).getByText('in 1 month')).toBeInTheDocument()
    })

    // What a bare hover handler would not answer: the trigger is focusable and opens from the
    //   keyboard, which is `CommonPopoverWithTrigger`'s doing rather than this component's.
    // Focused without the pointer, deliberately: `events.type` would click first, and the pointer
    //   events that come with a click open the popover through the hover watcher - the assertion
    //   would then hold with the `Space` handler deleted.
    it('opens from the keyboard', async () => {
      const view = renderWithSchedules()

      triggerOf(view).focus()
      await view.events.keyboard('{Space}')

      const popover = await view.findByRole('region')

      expect(within(popover).getAllByRole('listitem')).toHaveLength(3)
    })

    it('closes again when the pointer leaves', async () => {
      const view = renderWithSchedules()

      await view.events.hover(triggerOf(view))
      expect(await view.findByRole('region')).toBeInTheDocument()

      await view.events.unhover(triggerOf(view))

      await waitFor(() => {
        expect(view.queryByRole('region')).not.toBeInTheDocument()
      })
    })

    // The badge advances past a change that falls due while the page is open; the list behind it has
    //   to do the same, or it would render a *scheduled* change in the past tense ("1 minute ago")
    //   directly under a badge that has already moved on.
    it('drops a change that falls due from the list as well', async () => {
      const view = renderWithSchedules()

      await view.events.hover(triggerOf(view))
      expect(within(await view.findByRole('region')).getAllByRole('listitem')).toHaveLength(3)

      reactiveNow.value = new Date(inDays(3))

      await waitFor(() => {
        expect(within(view.getByRole('region')).getAllByRole('listitem')).toHaveLength(2)
      })

      const popover = view.getByRole('region')

      expect(within(popover).queryByText('Internal')).not.toBeInTheDocument()
      expect(within(popover).getByText('Published')).toBeInTheDocument()
    })

    // Nothing gates the popover of its own: no schedule means no badge, and the badge is the
    //   trigger.
    it('offers no trigger at all when nothing is scheduled', () => {
      const view = renderDetails({
        visibility: EnumKnowledgeBaseVisibility.Draft,
        visibilitySchedules: [],
      })

      expect(view.queryByRole('button')).not.toBeInTheDocument()
      expect(view.queryByRole('region')).not.toBeInTheDocument()
    })
  })
})
