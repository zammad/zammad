// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'
import { ref } from 'vue'

import { generateObjectData } from '#tests/graphql/builders/index.ts'
import { renderComponent } from '#tests/support/components/index.ts'

import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import TopBarHeaderCompact from '#desktop/pages/user/components/UserDetailTopBar/TopBarHeaderCompact.vue'
import type { DetailViewActionPlugin } from '#desktop/types/actions.ts'

const copyUserDisplayNameToClipboard = vi.fn()
const topLevelActions = ref<DetailViewActionPlugin[]>([])
const secondLevelActions = ref<DetailViewActionPlugin[]>([])

vi.mock('#desktop/pages/user/components/UserDetailTopBar/useTopBarHeader.ts', () => ({
  useTopBarHeader: () => ({
    copyUserDisplayNameToClipboard,
    allowedTopLevelActions: topLevelActions,
    secondLevelActions,
  }),
}))

const user = generateObjectData('User', {
  id: convertToGraphQLId('User', 2),
  internalId: 2,
  fullname: 'Nicole Braun',
  vip: false,
})

const renderTopBarHeaderCompact = (userDisplayName = 'Nicole Braun') =>
  renderComponent(TopBarHeaderCompact, {
    props: { user, userDisplayName },
    router: true,
  })

describe('TopBarHeaderCompact', () => {
  beforeEach(() => {
    copyUserDisplayNameToClipboard.mockReset()
    topLevelActions.value = []
    secondLevelActions.value = []
  })

  it('shows the user info', () => {
    const view = renderTopBarHeaderCompact()

    expect(view.getByRole('img', { name: 'Avatar (Nicole Braun)' })).toBeInTheDocument()
  })

  it('shows a copy button regardless of the display name', () => {
    const view = renderTopBarHeaderCompact('')

    expect(view.getByRole('button', { name: 'Copy user display name' })).toBeInTheDocument()
  })

  it('copies the user display name to clipboard when clicked', async () => {
    const view = renderTopBarHeaderCompact()

    await view.events.click(view.getByRole('button', { name: 'Copy user display name' }))

    expect(copyUserDisplayNameToClipboard).toHaveBeenCalled()
  })

  it('renders top-level actions as buttons and triggers them with the user and router', async () => {
    const onClick = vi.fn()
    topLevelActions.value = [
      {
        key: 'new-ticket',
        label: 'New ticket',
        icon: 'plus-square-fill',
        order: 200,
        topLevel: true,
        onClick,
      },
    ]

    const view = renderTopBarHeaderCompact()

    await view.events.click(view.getByRole('button', { name: 'New ticket' }))

    expect(onClick).toHaveBeenCalledWith(user, expect.anything())
  })

  it('renders second-level actions inside the action menu', async () => {
    const onClick = vi.fn()
    secondLevelActions.value = [
      {
        key: 'edit-user',
        label: 'Edit',
        icon: 'pencil',
        order: 100,
        topLevel: false,
        onClick,
      },
    ]

    const view = renderTopBarHeaderCompact()

    await view.events.click(view.getByRole('button', { name: 'Additional actions' }))

    const menu = await view.findByRole('menu')

    await view.events.click(within(menu).getByText('Edit'))

    expect(onClick).toHaveBeenCalledWith(user)
  })
})
