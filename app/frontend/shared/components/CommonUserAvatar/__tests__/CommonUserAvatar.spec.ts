// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { useDateFormat } from '@vueuse/shared'

import { renderComponent } from '#tests/support/components/index.ts'

import logo from '#shared/components/CommonUserAvatar/assets/logo.svg'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { initializeUserAvatarClasses } from '#shared/initializer/initializeUserAvatarClasses.ts'
import { SYSTEM_USER_ID } from '#shared/utils/constants.ts'

import CommonUserAvatar, { type Props } from '../CommonUserAvatar.vue'

const USER_ID = convertToGraphQLId('User', '123')

vi.hoisted(() => {
  vi.setSystemTime(new Date('2024-11-11T00:00:00Z'))
})

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
      backgroundImage: `url(/${logo})`,
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

  it('renders active', async () => {
    const view = renderComponent(CommonUserAvatar, {
      props: <Props>{
        entity: {
          id: USER_ID,
          active: true,
        },
      },
    })

    const avatar = view.getByTestId('common-avatar')

    expect(avatar).not.toHaveClass('opacity-60')

    await view.rerender(<Props>{
      entity: {
        id: USER_ID,
        active: false,
      },
    })

    expect(avatar).toHaveClass('opacity-60')
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

  describe('out of office state', () => {
    let today: string
    beforeAll(() => {
      today = useDateFormat(new Date(), 'YYYY-MM-DD').value
    })

    it('out of office date is in present', async () => {
      const view = renderComponent(CommonUserAvatar, {
        props: <Props>{
          entity: {
            id: USER_ID,
            active: true,
          },
        },
      })

      await view.rerender(<Props>{
        entity: {
          id: USER_ID,
          outOfOffice: true,
          outOfOfficeStartAt: '2024-10-11',
          outOfOfficeEndAt: '2024-12-11',
        },
      })

      const avatar = view.getByTestId('common-avatar')

      expect(avatar).toHaveClass('opacity-60')
    })

    it('out of office date is in past', async () => {
      const view = renderComponent(CommonUserAvatar, {
        props: <Props>{
          entity: {
            id: USER_ID,
            active: true,
          },
        },
      })

      const [year, month, day] = today.split('-')
      const outOfOfficeStartAt = `${year}-${(+month - 2).toString().padStart(2, '0')}-${day}`
      const outOfOfficeEndAt = `${year}-${(+month - 1).toString().padStart(2, '0')}-${day}`

      await view.rerender(<Props>{
        entity: {
          id: USER_ID,
          outOfOffice: true,
          outOfOfficeStartAt,
          outOfOfficeEndAt,
        },
      })

      const avatar = view.getByTestId('common-avatar')

      expect(avatar).not.toHaveClass('grayscale-[70%]')
    })

    it('out of office date is in future', async () => {
      const view = renderComponent(CommonUserAvatar, {
        props: <Props>{
          entity: {
            id: USER_ID,
            active: true,
          },
        },
      })

      await view.rerender(<Props>{
        entity: {
          id: USER_ID,
          outOfOffice: true,
          outOfOfficeStartAt: '2024-12-11',
          outOfOfficeEndAt: '2025-01-11',
        },
      })

      const avatar = view.getByTestId('common-avatar')

      expect(avatar).not.toHaveClass('grayscale-[70%]')
    })
  })
})
