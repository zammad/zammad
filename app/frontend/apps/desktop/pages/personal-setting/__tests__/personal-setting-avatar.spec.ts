// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'
import * as VueUse from '@vueuse/core'
import { defineComponent, ref } from 'vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { mockUserCurrentAvatarAddMutation } from '#shared/entities/user/current/graphql/mutations/userCurrentAvatarAdd.mocks.ts'
import {
  mockUserCurrentAvatarDeleteMutation,
  waitForUserCurrentAvatarDeleteMutationCalls,
} from '#shared/entities/user/current/graphql/mutations/userCurrentAvatarDelete.mocks.ts'

import {
  mockUserCurrentAvatarSelectMutation,
  waitForUserCurrentAvatarSelectMutationCalls,
} from '../graphql/mutations/userCurrentAvatarSelect.mocks.ts'
import { mockUserCurrentAvatarListQuery } from '../graphql/queries/userCurrentAvatarList.mocks.ts'

vi.mock('vue-advanced-cropper', () => {
  const Cropper = defineComponent({
    emits: ['change'],
    mounted() {
      this.$emit('change', {
        canvas: {
          toDataURL() {
            return 'cropped image url'
          },
        },
      })
    },
    template: '<div></div>',
  })

  return {
    Cropper,
  }
})

describe('avatar personal settings', () => {
  beforeEach(() => {
    mockUserCurrent({
      firstname: 'John',
      lastname: 'Doe',
    })
  })

  it('shows all the avatars of the current user', async () => {
    mockUserCurrentAvatarListQuery({
      userCurrentAvatarList: [
        {
          default: true,
          initial: true,
          deletable: false,
        },
        {
          default: false,
          initial: false,
          deletable: true,
        },
        {
          default: false,
          initial: false,
          deletable: true,
        },
      ],
    })

    const view = await visitView('/personal-setting/avatar')

    const mainContent = within(view.getByRole('main'))
    const avatars = await mainContent.findAllByTestId('common-avatar')

    expect(avatars).toHaveLength(3)

    expect(view.getByRole('button', { name: 'Upload' })).toBeInTheDocument()
    expect(view.getByRole('button', { name: 'Camera' })).toBeInTheDocument()
  })

  it('can select an avatar to be the new default one', async () => {
    mockUserCurrentAvatarListQuery({
      userCurrentAvatarList: [
        {
          default: true,
          initial: true,
          deletable: false,
        },
        {
          default: false,
          initial: false,
          deletable: true,
        },
        {
          default: false,
          initial: false,
          deletable: true,
        },
      ],
    })

    const view = await visitView('/personal-setting/avatar')

    const mainContent = within(view.getByRole('main'))
    let avatars = await mainContent.findAllByTestId('common-avatar')

    expect(avatars[0]).toHaveClass('avatar-selected')

    mockUserCurrentAvatarSelectMutation({
      userCurrentAvatarSelect: {
        success: true,
      },
    })

    await view.events.click(avatars[1])

    const calls = await waitForUserCurrentAvatarSelectMutationCalls()
    expect(calls).toHaveLength(1)

    avatars = await mainContent.findAllByTestId('common-avatar')

    expect(avatars[0]).not.toHaveClass('avatar-selected')
    expect(avatars[1]).toHaveClass('avatar-selected')
  })

  it('can delete an avatar', async () => {
    mockUserCurrentAvatarListQuery({
      userCurrentAvatarList: [
        {
          default: true,
          initial: true,
          deletable: false,
        },
        {
          default: false,
          initial: false,
          deletable: true,
        },
      ],
    })

    const view = await visitView('/personal-setting/avatar')

    const mainContent = within(view.getByRole('main'))
    let avatars = await mainContent.findAllByTestId('common-avatar')

    expect(avatars).toHaveLength(2)

    const deleteButton = await view.findByRole('button', {
      name: 'Delete this avatar',
    })
    expect(deleteButton).toBeInTheDocument()

    mockUserCurrentAvatarDeleteMutation({
      userCurrentAvatarDelete: {
        success: true,
      },
    })

    await view.events.click(deleteButton)

    await waitForNextTick()

    expect(
      await view.findByRole('dialog', { name: 'Delete Object' }),
    ).toBeInTheDocument()

    await view.events.click(view.getByRole('button', { name: 'Delete Object' }))

    const calls = await waitForUserCurrentAvatarDeleteMutationCalls()
    expect(calls).toHaveLength(1)

    avatars = await mainContent.findAllByTestId('common-avatar')

    expect(avatars).toHaveLength(1)
    expect(avatars[0]).toHaveTextContent('JD')
  })

  it('upload new avatar by file', async () => {
    mockUserCurrentAvatarListQuery({
      userCurrentAvatarList: [
        {
          default: true,
          initial: true,
          deletable: false,
        },
      ],
    })

    const view = await visitView('/personal-setting/avatar')

    const mainContent = within(view.getByRole('main'))
    let avatars = await mainContent.findAllByTestId('common-avatar')

    expect(avatars).toHaveLength(1)
    expect(avatars[0]).toHaveClass('avatar-selected')

    const fileUploadButton = view.getByRole('button', {
      name: 'Upload',
    })
    expect(fileUploadButton).toBeInTheDocument()

    const file = new File([], 'test.jpg', { type: 'image/jpeg' })
    await view.events.upload(view.getByTestId('fileUploadInput'), file)

    await waitForNextTick()

    const flyout = await view.findByRole('complementary', {
      name: 'Crop Image',
    })
    expect(flyout).toBeInTheDocument()

    const flyoutContent = within(flyout)
    expect(
      await flyoutContent.findByTestId('common-avatar'),
    ).toBeInTheDocument()

    mockUserCurrentAvatarAddMutation({
      userCurrentAvatarAdd: {
        avatar: {
          default: true,
          initial: true,
          deletable: false,
        },
      },
    })

    await view.events.click(view.getByRole('button', { name: 'Save' }))

    avatars = await mainContent.findAllByTestId('common-avatar')

    expect(avatars).toHaveLength(2)
    expect(avatars[0]).not.toHaveClass('avatar-selected')
    expect(avatars[1]).toHaveClass('avatar-selected')
  })

  describe('with camera flyout', () => {
    let mockPermissionState = 'granted'
    let originalMediaDevices: MediaDevices

    beforeAll(() => {
      originalMediaDevices = navigator.mediaDevices

      // Redefine mediaDevices to be writable
      Object.defineProperty(navigator, 'mediaDevices', {
        writable: true,
        value: {
          getUserMedia: vi.fn().mockResolvedValue({
            getTracks: () => [
              {
                kind: 'video',
                stop: vi.fn(),
              },
            ],
          }),
        },
      })

      vi.spyOn(VueUse, 'usePermission').mockImplementation(() => {
        // Return a mock ref object based on the permission you are testing
        // You can control the returned value based on the permissionName if needed
        return ref(
          mockPermissionState,
        ) as unknown as VueUse.UsePermissionReturnWithControls
      })
    })

    afterAll(() => {
      // Restore original mediaDevices
      Object.defineProperty(navigator, 'mediaDevices', {
        writable: true,
        value: originalMediaDevices,
      })
    })

    beforeEach(() => {
      mockUserCurrentAvatarListQuery({
        userCurrentAvatarList: [
          {
            default: true,
            initial: true,
            deletable: false,
          },
        ],
      })
    })

    it('upload new avatar by camera', async () => {
      const view = await visitView('/personal-setting/avatar')

      const mainContent = within(view.getByRole('main'))
      let avatars = await mainContent.findAllByTestId('common-avatar')

      expect(avatars).toHaveLength(1)
      expect(avatars[0]).toHaveClass('avatar-selected')

      const cameraButton = view.getByRole('button', {
        name: 'Camera',
      })

      await view.events.click(cameraButton)

      const flyout = await view.findByRole('complementary', {
        name: 'Camera',
      })
      expect(flyout).toBeInTheDocument()

      expect(
        await view.findByLabelText(
          'Use the camera to take a photo for the avatar.',
        ),
      ).toBeInTheDocument()

      const captureButton = view.getByRole('button', {
        name: 'Capture From Camera',
      })

      await view.events.click(captureButton)

      mockUserCurrentAvatarAddMutation({
        userCurrentAvatarAdd: {
          avatar: {
            default: true,
            initial: false,
            deletable: false,
          },
        },
      })

      await view.events.click(view.getByRole('button', { name: 'Save' }))

      avatars = await mainContent.findAllByTestId('common-avatar')

      expect(avatars).toHaveLength(2)
      expect(avatars[0]).not.toHaveClass('avatar-selected')
      expect(avatars[1]).toHaveClass('avatar-selected')
    })

    it('should show forbidden access for camera', async () => {
      mockPermissionState = 'denied'

      const view = await visitView('/personal-setting/avatar')

      const cameraButton = view.getByRole('button', {
        name: 'Camera',
      })

      await view.events.click(cameraButton)

      const flyout = await view.findByRole('complementary', {
        name: 'Camera',
      })
      expect(flyout).toBeInTheDocument()

      expect(
        view.getByText(
          'Accessing your camera is forbidden. Please check your settings.',
        ),
      ).toBeInTheDocument()
    })
  })
})
