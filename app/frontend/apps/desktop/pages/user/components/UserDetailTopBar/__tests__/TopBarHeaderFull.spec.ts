// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'
import { ref } from 'vue'

import { generateObjectData } from '#tests/graphql/builders/index.ts'
import { renderComponent } from '#tests/support/components/index.ts'

import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import TopBarHeaderFull from '#desktop/pages/user/components/UserDetailTopBar/TopBarHeaderFull.vue'
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

const renderTopBarHeaderFull = (userDisplayName = 'Nicole Braun') =>
  renderComponent(TopBarHeaderFull, {
    props: { user, userDisplayName },
    router: true,
  })

describe('TopBarHeaderFull', () => {
  beforeEach(() => {
    copyUserDisplayNameToClipboard.mockReset()
    topLevelActions.value = []
    secondLevelActions.value = []
  })

  it('shows breadcrumb with the user label and display name', () => {
    const view = renderTopBarHeaderFull()

    expect(view.getByText('User')).toBeInTheDocument()
    expect(view.getByRole('heading', { name: 'Nicole Braun' })).toBeInTheDocument()
  })

  it('shows the user info', () => {
    const view = renderTopBarHeaderFull()

    expect(view.getByRole('img', { name: 'Avatar (Nicole Braun)' })).toBeInTheDocument()
  })

  it('shows a copy button when a display name is present', () => {
    const view = renderTopBarHeaderFull()

    expect(view.getByRole('button', { name: 'Copy user display name' })).toBeInTheDocument()
  })

  it('hides the copy button when there is no display name', () => {
    const view = renderTopBarHeaderFull('')

    expect(view.queryByRole('button', { name: 'Copy user display name' })).not.toBeInTheDocument()
  })

  it('copies the user display name to clipboard when clicked', async () => {
    const view = renderTopBarHeaderFull()

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

    const view = renderTopBarHeaderFull()

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

    const view = renderTopBarHeaderFull()

    await view.events.click(view.getByRole('button', { name: 'Additional actions' }))

    const menu = await view.findByRole('menu')

    await view.events.click(within(menu).getByText('Edit'))

    expect(onClick).toHaveBeenCalledWith(user)
  })
})
