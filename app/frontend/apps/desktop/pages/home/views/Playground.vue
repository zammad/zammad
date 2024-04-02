<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->
<!-- eslint-disable zammad/zammad-detect-translatable-string -->

<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { storeToRefs } from 'pinia'
import { reset } from '@formkit/core'

import { useSessionStore } from '#shared/stores/session.ts'

import CommonAlert from '#shared/components/CommonAlert/CommonAlert.vue'
import Form from '#shared/components/Form/Form.vue'
import type { FormValues } from '#shared/components/Form/types.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonButtonGroup from '#desktop/components/CommonButtonGroup/CommonButtonGroup.vue'
import CommonProgressBar from '#desktop/components/CommonProgressBar/CommonProgressBar.vue'
import type { CommonButtonItem } from '#desktop/components/CommonButtonGroup/types.ts'
import CommonPopover from '#desktop/components/CommonPopover/CommonPopover.vue'
import CommonPopoverMenu from '#desktop/components/CommonPopover/CommonPopoverMenu.vue'
import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import ThemeSwitch from '#desktop/components/ThemeSwitch/ThemeSwitch.vue'
import { usePopover } from '#desktop/components/CommonPopover/usePopover.ts'

const alphabetOptions = computed(() =>
  [...Array(26).keys()].map((i) => ({
    value: i,
    label: `Item ${String.fromCharCode(65 + i)}`,
    disabled: Math.random() < 0.5,
  })),
)

const longOption = ref({
  value: 999,
  label:
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, nullam pulvinar nunc sapien, vitae malesuada justo interdum feugiat, mauris odio, mattis et malesuada quis, vulputate vitae enim',
})

const treeselectOptions = [
  {
    value: 0,
    label: 'Item A',
    children: [
      {
        value: 1,
        label: 'Item 1',
        children: [
          {
            value: 2,
            label: 'Item I',
          },
          {
            value: 3,
            label: 'Item II',
          },
          {
            value: 4,
            label: 'Item III',
          },
        ],
      },
      {
        value: 5,
        label: 'Item 2',
        children: [
          ...[longOption.value],
          {
            value: 6,
            label: 'Item IV',
          },
        ],
      },
      {
        value: 7,
        label: 'Item 3',
      },
    ],
  },
  {
    value: 8,
    label: 'Item B',
  },
  {
    value: 9,
    label: 'Ítem C',
  },
]

const buttonGroupOptions: CommonButtonItem[] = [
  {
    label: 'Button 1',
    variant: 'primary',
    icon: 'logo-flat',
    onActionClick: () => console.debug('Button 1 clicked'),
  },
  {
    label: 'Button 2',
    variant: 'secondary',
  },
  {
    label: 'Button 3',
    variant: 'tertiary',
  },
  {
    label: 'Button 4',
    variant: 'submit',
  },
  {
    label: 'Button 5',
    variant: 'danger',
  },
]

const formSchema = [
  {
    isLayout: true,
    element: 'div',
    attrs: {
      class: 'grid md:grid-cols-2 gap-y-2.5 gap-x-3',
    },
    children: [
      {
        name: 'select_0',
        label: 'Column select',
        type: 'select',
        outerClass: 'col-span-1',
        props: {
          maxLength: 150,
          options: [...alphabetOptions.value, ...[longOption.value]],
          clearable: true,
        },
      },
      {
        name: 'toggle_1',
        label: 'Column toggle',
        type: 'toggle',
        outerClass: 'col-span-1',
        wrapperClass: 'md:mt-6',
        props: {
          variants: {
            true: 'yes',
            false: 'no',
          },
        },
      },
      {
        name: 'toggle_2',
        label: 'Row toggle',
        type: 'toggle',
        props: {
          variants: {
            true: 'yes',
            false: 'no',
          },
        },
      },
    ],
  },
  {
    name: 'group_permission_0',
    label: 'Group permissions',
    type: 'groupPermissions',
    props: {
      options: [
        {
          value: 1,
          label: 'Users',
        },
        {
          value: 2,
          label: 'some_group1',
          children: [
            {
              value: 3,
              label: 'Nested group',
            },
          ],
        },
      ],
    },
  },
  {
    type: 'select',
    name: 'select_1',
    label: 'Single select',
    clearable: true,
    props: {
      options: [...alphabetOptions.value, ...[longOption.value]],
      link: '/',
      linkIcon: 'person-add',
    },
  },
  {
    type: 'select',
    name: 'select_2',
    label: 'Multi select',
    clearable: true,
    props: {
      multiple: true,
      options: [...alphabetOptions.value, ...[longOption.value]],
    },
  },
  {
    type: 'treeselect',
    name: 'treeselect_1',
    label: 'Single treeselect',
    clearable: true,
    props: {
      options: treeselectOptions,
    },
  },
  {
    type: 'treeselect',
    name: 'treeselect_2',
    label: 'Multi treeselect',
    clearable: true,
    props: {
      multiple: true,
      options: treeselectOptions,
    },
  },
  {
    type: 'toggleList',
    name: 'roles',
    label: 'Roles',
    props: {
      options: [
        { value: 3, label: 'name only' },
        { value: 1, label: 'Long name', description: 'Note here' },
        {
          value: 1111,
          label: 'Another long name',
          description: 'Note here again',
        },
      ],
    },
  },
]

const formInitialValues: FormValues = { roles: [3, 1] }

const progressBarValue = ref(0)

const increaseProgressBar = () => {
  progressBarValue.value += 25
}

onMounted(() => {
  setInterval(increaseProgressBar, 2000)
})

watch(progressBarValue, (newValue) => {
  if (newValue < 100) return

  setTimeout(() => {
    progressBarValue.value = 0
  }, 1000)
})

const session = useSessionStore()
const { user } = storeToRefs(session)

const { popover, popoverTarget, toggle } = usePopover()

const appearance = ref('auto')
</script>

<template>
  <div class="w-1/2 ltr:ml-2 rtl:mr-2">
    <h2 class="text-xl">Buttons</h2>

    <h3>Text only</h3>
    <div class="space-x-3 py-2 flex">
      <CommonButton variant="primary" />
      <CommonButton variant="secondary" />
      <CommonButton variant="tertiary" />
      <CommonButton variant="submit" />
      <CommonButton variant="danger" />
    </div>

    <h3>With icon</h3>
    <div class="space-x-3 py-2 flex">
      <CommonButton variant="primary" prefix-icon="logo-flat" />
      <CommonButton variant="secondary" prefix-icon="logo-flat" />
      <CommonButton variant="tertiary" prefix-icon="logo-flat" />
      <CommonButton variant="submit" prefix-icon="logo-flat" />
      <CommonButton variant="danger" prefix-icon="logo-flat" />
    </div>

    <h3>Icon only</h3>
    <div class="space-x-3 py-2 flex items-center">
      <CommonButton variant="primary" icon="logo-flat" />
      <CommonButton variant="secondary" icon="logo-flat" />
      <CommonButton variant="tertiary" icon="logo-flat" />
      <CommonButton variant="submit" icon="logo-flat" />
      <CommonButton variant="danger" icon="logo-flat" />
      <CommonButton variant="primary" icon="logo-flat" size="medium" />
      <CommonButton variant="secondary" icon="logo-flat" size="medium" />
      <CommonButton variant="tertiary" icon="logo-flat" size="medium" />
      <CommonButton variant="submit" icon="logo-flat" size="medium" />
      <CommonButton variant="danger" icon="logo-flat" size="medium" />
      <CommonButton variant="primary" icon="logo-flat" size="large" />
      <CommonButton variant="secondary" icon="logo-flat" size="large" />
      <CommonButton variant="tertiary" icon="logo-flat" size="large" />
      <CommonButton variant="submit" icon="logo-flat" size="large" />
      <CommonButton variant="danger" icon="logo-flat" size="large" />
    </div>

    <h3>Misc</h3>
    <div class="space-x-3 space-y-2 py-2 flex-wrap">
      <CommonButton variant="submit" block>Block button</CommonButton>
      <CommonButton variant="primary" disabled>Disabled button</CommonButton>
      <CommonButton variant="secondary" disabled>Disabled button</CommonButton>
      <CommonButton variant="tertiary" disabled>Disabled button</CommonButton>
      <CommonButton variant="submit" disabled>Disabled button</CommonButton>
      <CommonButton variant="danger" disabled>Disabled button</CommonButton>
    </div>

    <h3>Group</h3>
    <div class="w-1/2 space-x-3 space-y-2 py-2">
      <CommonButtonGroup :items="buttonGroupOptions" />
    </div>
  </div>

  <div class="w-1/2 ltr:ml-2 rtl:mr-2">
    <h2 class="text-xl">Alerts</h2>

    <CommonAlert
      variant="info"
      dismissible
      link="https://youtu.be/U6n2NcJ7rLc"
      link-text="Party 🎉"
      class="mb-2.5"
      >It's Friday!</CommonAlert
    >
    <CommonAlert variant="success" class="mb-2.5"
      >Hooray! Ticket got updated.</CommonAlert
    >
    <CommonAlert variant="warning" class="mb-2.5"
      >Heee! You're typing too fast.</CommonAlert
    >
    <CommonAlert variant="danger" class="mb-2.5"
      >Ooops! You broke it.</CommonAlert
    >
  </div>

  <div class="ltr:ml-2 rtl:mr-2">
    <h2>Labels</h2>
    <CommonLabel size="small" prefix-icon="logo" suffix-icon="logo-flat"
      >Small</CommonLabel
    >

    <br />

    <CommonLabel size="medium" prefix-icon="logo" suffix-icon="logo-flat"
      >Medium</CommonLabel
    >

    <br />

    <CommonLabel size="large" prefix-icon="logo" suffix-icon="logo-flat"
      >Large</CommonLabel
    >

    <br />

    <CommonLabel size="xl" prefix-icon="logo" suffix-icon="logo-flat"
      >Extra large</CommonLabel
    >
  </div>

  <div class="ltr:ml-2 rtl:mr-2">
    <h2>Badges</h2>

    <CommonBadge class="ltr:mr-2 rtl:ml-2" variant="neutral"
      >Neutral</CommonBadge
    >

    <CommonBadge class="ltr:mr-2 rtl:ml-2" variant="info">Info</CommonBadge>

    <CommonBadge class="ltr:mr-2 rtl:ml-2" variant="success"
      >Success</CommonBadge
    >

    <CommonBadge class="ltr:mr-2 rtl:ml-2" variant="warning"
      >Warning</CommonBadge
    >

    <CommonBadge class="ltr:mr-2 rtl:ml-2" variant="danger">Danger</CommonBadge>

    <CommonBadge
      class="ltr:mr-2 rtl:ml-2 dark:bg-pink-300 bg-pink-300 text-white"
      variant="custom"
      >Custom</CommonBadge
    >
  </div>

  <div class="w-1/5 ltr:ml-2 rtl:mr-2">
    <h2>Progress Bar</h2>

    <div class="flex flex-col gap-3">
      <div class="flex flex-col gap-2">
        <CommonLabel size="small">What is the meaning of life?</CommonLabel>
        <CommonProgressBar />
      </div>

      <div class="flex items-end gap-2">
        <div class="mb-1 grow flex flex-col gap-1">
          <div class="flex justify-between">
            <CommonLabel size="small">Organizations</CommonLabel>
            <CommonLabel
              class="text-stone-200 dark:text-neutral-500"
              size="small"
            >
              {{ progressBarValue }} of 100
            </CommonLabel>
          </div>

          <CommonProgressBar :value="progressBarValue.toString()" max="100" />
        </div>

        <CommonIcon
          class="shrink-0 fill-green-500"
          :class="progressBarValue !== 100 ? 'invisible' : undefined"
          name="check2"
          size="tiny"
          decorative
        />
      </div>
    </div>
  </div>

  <div class="ltr:ml-2 rtl:mr-2">
    <h2 class="text-lg">Popover</h2>

    <template v-if="user">
      <CommonPopover
        ref="popover"
        :owner="popoverTarget"
        arrow-placement="start"
        orientation="autoVertical"
      >
        <CommonPopoverMenu
          header-label="Erika Mustermann"
          :items="[
            {
              key: 'appearance',
              label: __('Appearance'),
              icon: 'brightness-alt-high',
            },
            {
              key: 'keyboard-shortcuts',
              label: __('Keyboard shortcuts'),
              onClick: () => {
                console.log('OPEN KEYBOARD SHORTCUTS DIALOG')
              },
              icon: 'keyboard',
            },
            {
              key: 'profile-settings',
              label: __('Profile settings'),
              link: '/profile',
              icon: 'person-gear',
            },
            {
              key: 'sign-out',
              label: __('Sign out'),
              link: '/logout',
              icon: 'box-arrow-in-right',
              seperatorTop: true,
            },
          ]"
        >
          <template #itemRight="{ key }">
            <div v-if="key === 'appearance'" class="px-2 flex items-center">
              <ThemeSwitch v-model="appearance" size="small" />
            </div>
          </template>
        </CommonPopoverMenu>
      </CommonPopover>
      <button ref="popoverTarget" @click="toggle">
        <CommonUserAvatar
          :entity="user"
          size="large"
          personal
          class="bg-red-300"
        />
      </button>
    </template>
  </div>

  <div class="w-1/2 ltr:ml-2 rtl:mr-2">
    <h2 class="text-lg">Form</h2>

    <Form
      id="playground-form"
      class="mb-96"
      form-class="mb-2.5 space-y-2.5"
      :schema="formSchema"
      :initial-values="formInitialValues"
      @submit="console.debug($event)"
    >
      <template #after-fields>
        <div class="mt-5 flex justify-end items-center gap-2">
          <CommonButton
            variant="secondary"
            size="medium"
            @click="reset('playground-form')"
          >
            Reset
          </CommonButton>
          <CommonButton variant="submit" type="submit" size="medium">
            Submit
          </CommonButton>
        </div>
      </template>
    </Form>
  </div>
</template>
