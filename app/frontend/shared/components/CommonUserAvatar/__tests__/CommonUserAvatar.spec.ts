// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { SYSTEM_USER_ID } from '#shared/utils/constants.ts'
import { initializeUserAvatarClasses } from '#shared/initializer/initializeUserAvatarClasses.ts'
import { renderComponent } from '#tests/support/components/index.ts'

import CommonUserAvatar, { type Props } from '../CommonUserAvatar.vue'

const USER_ID = convertToGraphQLId('User', '123')

initializeUserAvatarClasses({
  backgroundColors: [
    'bg-gray',
    'bg-red-bright',
    'bg-yellow',
    'bg-blue',
    'bg-green',
    'bg-pink',
    'bg-orange',
  ],
})

describe('CommonUserAvatar', () => {
  it('renders user avatar', async () => {
    const view = renderComponent(CommonUserAvatar, {
      props: <Props>{
        entity: {
          id: USER_ID,
          firstname: 'John',
          lastname: 'Doe',
        },
      },
    })

    const avatar = view.getByTestId('common-avatar')

    expect(avatar).toHaveTextContent('JD')
    expect(avatar).toHaveClass('bg-blue')

    await view.rerender(<Props>{
      entity: {
        id: USER_ID,
        image: '100.png',
        firstname: 'John',
        lastname: 'Doe',
      },
    })

    expect(avatar).toHaveStyle(
      'background-image: url(/api/users/image/100.png)',
    )
    expect(avatar).not.toHaveTextContent('JD')
  })

  it('renders system user', () => {
    const view = renderComponent(CommonUserAvatar, {
      props: <Props>{
        entity: {
          id: SYSTEM_USER_ID,
        },
      },
    })

    const avatar = view.getByTestId('common-avatar')

    expect(avatar).toHaveStyle({
      backgroundImage:
        'url(/app/frontend/shared/components/CommonUserAvatar/assets/logo.svg)',
    })
  })

  it('renders icon by source', async () => {
    const view = renderComponent(CommonUserAvatar, {
      props: <Props>{
        entity: {
          id: USER_ID,
          source: 'twitter',
        },
      },
    })

    expect(view.getByIconName('twitter')).toBeInTheDocument()

    await view.rerender(<Props>{
      entity: {
        id: USER_ID,
        source: 'facebook',
      },
    })

    expect(view.getByIconName('facebook')).toBeInTheDocument()

    await view.rerender(<Props>{
      entity: {
        id: USER_ID,
        source: 'some-unknown-source',
      },
    })

    expect(view.queryByIconName('some-unknown-source')).not.toBeInTheDocument()
  })

  it('renders active and outOfOffice', async () => {
    const view = renderComponent(CommonUserAvatar, {
      props: <Props>{
        entity: {
          id: USER_ID,
          active: true,
        },
      },
    })

    const avatar = view.getByTestId('common-avatar')

    expect(avatar).not.toHaveClass('grayscale')
    expect(avatar).not.toHaveClass('grayscale-[70%]')

    await view.rerender(<Props>{
      entity: {
        id: USER_ID,
        active: false,
        outOfOffice: true,
      },
    })

    expect(avatar).toHaveClass('grayscale-[70%]')

    await view.rerender(<Props>{
      entity: {
        id: USER_ID,
        active: false,
        outOfOffice: false,
      },
    })

    expect(avatar).toHaveClass('grayscale')
  })

  it('renders crown for vip', async () => {
    const view = renderComponent(CommonUserAvatar, {
      props: <Props>{
        entity: {
          id: USER_ID,
          vip: true,
        },
      },
    })

    expect(view.getByIconName('crown')).toBeInTheDocument()

    await view.rerender(<Props>{
      entity: {
        id: USER_ID,
        vip: true,
      },
      personal: true,
    })

    expect(view.queryByIconName('crown')).not.toBeInTheDocument()
  })

  it('can render initials only', async () => {
    const view = renderComponent(CommonUserAvatar, {
      props: <Props>{
        entity: {
          id: USER_ID,
          image: '100.png',
          firstname: 'John',
          lastname: 'Doe',
        },
        initialsOnly: true,
      },
    })

    const avatar = view.getByTestId('common-avatar')

    expect(avatar).toHaveTextContent('JD')
    expect(avatar).toHaveClass('bg-blue')

    expect(avatar).not.toHaveStyle(
      'background-image: url(/api/users/image/100.png)',
    )
  })
})
