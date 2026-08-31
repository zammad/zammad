// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getByIconName, queryByIconName } from '#tests/support/components/iconQueries.ts'
import renderComponent from '#tests/support/components/renderComponent.ts'
import { nullableMock } from '#tests/support/utils.ts'

import type { TaskbarLiveAppUser } from '#shared/entities/taskbar/types.ts'
import { EnumTaskbarApp } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import KnowledgeBaseAnswerEditLiveUsers, {
  type Props,
} from '../KnowledgeBaseAnswerEditLiveUsers.vue'

const liveUser = (internalId: number, editing = false): TaskbarLiveAppUser => ({
  user: nullableMock({
    __typename: 'User' as const,
    id: convertToGraphQLId('User', internalId),
    internalId,
    firstname: 'Editor',
    lastname: `${internalId}`,
    fullname: `Editor ${internalId}`,
    vip: false,
    active: true,
  }) as TaskbarLiveAppUser['user'],
  editing,
  // Recent enough not to count as idle, whatever the clock says.
  lastInteraction: new Date().toISOString(),
  app: EnumTaskbarApp.Desktop,
})

const renderLiveUsers = (props?: Partial<Props>) =>
  renderComponent(KnowledgeBaseAnswerEditLiveUsers, {
    props: { liveUserList: [liveUser(2), liveUser(3, true)], ...props },
    router: true,
    store: true,
  })

describe('KnowledgeBaseAnswerEditLiveUsers', () => {
  it('shows one avatar per editor, marking who is editing', () => {
    const wrapper = renderLiveUsers()

    const viewing = wrapper.getByRole('img', { name: 'Avatar (Editor 2)' })
    expect(queryByIconName(viewing.parentElement!, 'pencil')).not.toBeInTheDocument()

    const editing = wrapper.getByRole('img', { name: 'Avatar (Editor 3)' })
    expect(getByIconName(editing.parentElement!, 'pencil')).toBeInTheDocument()
  })

  // Nobody else editing has to leave the bar untouched rather than render an empty row that still
  //   takes its gap.
  it('renders nothing without live users', () => {
    const wrapper = renderLiveUsers({ liveUserList: [] })

    expect(wrapper.queryByRole('img')).not.toBeInTheDocument()
  })

  // Past the limit the rest collapses into one trigger, so a busy answer cannot push the update
  //   button off the bar.
  it('collapses everybody past the ninth into one popover', () => {
    const wrapper = renderLiveUsers({
      liveUserList: Array.from({ length: 12 }, (_, index) => liveUser(index + 2)),
    })

    expect(wrapper.getAllByRole('img', { name: /^Avatar \(Editor/ })).toHaveLength(8)
    // The shared trigger renders the count as bare text and carries no accessible name of its
    //   own - the same as in the ticket detail view's bar.
    expect(wrapper.getByText('+4')).toBeInTheDocument()
  })
})
