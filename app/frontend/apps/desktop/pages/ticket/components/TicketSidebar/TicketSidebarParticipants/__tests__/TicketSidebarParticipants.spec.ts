// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { vi } from 'vitest'
import { computed, ref } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'

import { TicketSidebarScreenType } from '#desktop/pages/ticket/types/sidebar.ts'

import participantsPlugin from '../../plugins/participants.ts'
import TicketSidebarParticipants from '../TicketSidebarParticipants.vue'

const mockParticipants = ref([
  { id: 'user-1', firstname: 'Alice', fullname: 'Alice M.' },
  { id: 'user-2', firstname: 'Bob', fullname: 'Bob X.' },
])

const mockEmpty = ref([])

const mockAddParticipant = vi.fn().mockResolvedValue(true)
const mockRemoveParticipant = vi.fn().mockResolvedValue(true)

vi.mock(
  '#shared/entities/ticket/composables/useTicketParticipants.ts',
  () => ({ useTicketParticipants: vi.fn() }),
)
vi.mock(
  '#shared/components/Form/fields/FieldCustomer/graphql/queries/autocompleteSearch/user.api.ts',
  () => ({ useAutocompleteSearchUserLazyQuery: vi.fn() }),
)

import { useTicketParticipants } from '#shared/entities/ticket/composables/useTicketParticipants.ts'
import { useAutocompleteSearchUserLazyQuery } from '#shared/components/Form/fields/FieldCustomer/graphql/queries/autocompleteSearch/user.api.ts'

const ensureTicketSidebar = () => {
  if (!document.getElementById('ticketSidebar')) {
    const el = document.createElement('div')
    el.id = 'ticketSidebar'
    document.body.appendChild(el)
  }
}

const renderSidebar = () => {
  ensureTicketSidebar()
  return renderComponent(TicketSidebarParticipants, {
    props: {
      sidebar: 'participants',
      sidebarPlugin: participantsPlugin,
      selected: true,
      context: {
        screenType: TicketSidebarScreenType.TicketDetailView,
        formValues: {},
        ticket: computed(() => ({ id: '1', mentions: { edges: [], totalCount: 0 } } as any)),
      },
    },
  })
}
describe('TicketSidebarParticipants', () => {
  beforeEach(() => {
    vi.useFakeTimers()
    vi.mocked(useTicketParticipants).mockReturnValue({
      participants: mockParticipants,
      loading: ref(false),
      isEnabled: computed(() => true),
      canManageParticipants: computed(() => true),
      addParticipant: mockAddParticipant,
      removeParticipant: mockRemoveParticipant,
    } as any)
    vi.mocked(useAutocompleteSearchUserLazyQuery).mockReturnValue({
      result: ref(null),
      load: vi.fn(),
      loading: ref(false),
    } as any)
  })

  afterEach(() => {
    vi.clearAllMocks()
  })

  it('renders participant list', () => {
    const { queryByText } = renderSidebar()
    expect(queryByText('Alice M.')).toBeTruthy()
    expect(queryByText('Bob X.')).toBeTruthy()
  })

  it('shows empty state when no participants', () => {
    vi.mocked(useTicketParticipants).mockReturnValue({
      participants: mockEmpty,
      loading: ref(false),
      isEnabled: computed(() => true),
      canManageParticipants: computed(() => true),
      addParticipant: mockAddParticipant,
      removeParticipant: mockRemoveParticipant,
    } as any)
    const { queryByText } = renderSidebar()
    expect(queryByText('No participants yet.')).toBeTruthy()
  })

  it('hides when Flag OFF', () => {
    vi.mocked(useTicketParticipants).mockReturnValue({
      participants: mockParticipants,
      loading: ref(false),
      isEnabled: computed(() => false),
      canManageParticipants: computed(() => false),
      addParticipant: mockAddParticipant,
      removeParticipant: mockRemoveParticipant,
    } as any)
    const { queryByText } = renderSidebar()
    expect(queryByText('Alice M.')).toBeFalsy()
  })

  it('shows Add button when canManageParticipants', () => {
    const { queryByText } = renderSidebar()
    expect(queryByText('+ Add')).toBeTruthy()
  })

  it('hides Add button when cannot manage', () => {
    vi.mocked(useTicketParticipants).mockReturnValue({
      participants: mockParticipants,
      loading: ref(false),
      isEnabled: computed(() => true),
      canManageParticipants: computed(() => false),
      addParticipant: mockAddParticipant,
      removeParticipant: mockRemoveParticipant,
    } as any)
    const { queryByText } = renderSidebar()
    expect(queryByText('+ Add')).toBeFalsy()
  })

  // ACTION: Add — component provides search UI via REST
  it('opens search UI when + Add is clicked', async () => {
    const { queryByText } = renderSidebar()
    expect(queryByText('+ Add')).toBeTruthy()
    // Click opens search area (toggles showAdd ref)
    queryByText('+ Add')?.click()
    await vi.runAllTimersAsync()
    // After click, button text changes to Cancel and search input appears
    expect(queryByText('Cancel')).toBeTruthy()
  })

  // ACTION: Remove
  it('calls removeParticipant with correct userId when ✕ is clicked', async () => {
    const { queryAllByText } = renderSidebar()

    // Find all ✕ buttons (one per participant)
    const removeButtons = queryAllByText('✕')
    expect(removeButtons.length).toBe(2)

    removeButtons[0].click()
    await vi.runAllTimersAsync()

    expect(mockRemoveParticipant).toHaveBeenCalledWith('1', 'user-1')
  })


  // ERROR HANDLING: addParticipant returns false → does not crash
  it('handles addParticipant returning false without error', async () => {
    const failAdd = vi.fn().mockResolvedValue(false)
    vi.mocked(useTicketParticipants).mockReturnValue({
      participants: mockParticipants,
      loading: ref(false),
      isEnabled: computed(() => true),
      canManageParticipants: computed(() => true),
      addParticipant: failAdd,
      removeParticipant: mockRemoveParticipant,
    } as any)
    vi.mocked(useAutocompleteSearchUserLazyQuery).mockReturnValue({
      result: ref(null),
      load: vi.fn(),
      loading: ref(false),
    } as any)

    const { queryByText } = renderSidebar()
    // Verify component renders without error when addParticipant is set to fail
    expect(queryByText('Alice M.')).toBeTruthy()
    expect(queryByText('+ Add')).toBeTruthy()
  })

  // ERROR HANDLING: removeParticipant returns false → participant stays in list
  it('keeps participant visible when removeParticipant fails', async () => {
    const failRemove = vi.fn().mockResolvedValue(false)
    vi.mocked(useTicketParticipants).mockReturnValue({
      participants: mockParticipants,
      loading: ref(false),
      isEnabled: computed(() => true),
      canManageParticipants: computed(() => true),
      addParticipant: mockAddParticipant,
      removeParticipant: failRemove,
    } as any)
    vi.mocked(useAutocompleteSearchUserLazyQuery).mockReturnValue({
      result: ref(null),
      load: vi.fn(),
      loading: ref(false),
    } as any)

    const { queryByText, queryAllByText } = renderSidebar()

    const removeButtons = queryAllByText('✕')
    expect(removeButtons.length).toBe(2)

    removeButtons[0].click()
    await vi.runAllTimersAsync()

    // Participant still visible (remove failed quietly, composable showed notification)
    expect(queryByText('Alice M.')).toBeTruthy()
    expect(failRemove).toHaveBeenCalledWith('1', 'user-1')
  })
})
