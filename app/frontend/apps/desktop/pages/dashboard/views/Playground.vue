<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->
<!-- eslint-disable zammad/zammad-detect-translatable-string -->

<script setup lang="ts">
import { computed, h, onMounted, ref, watch } from 'vue'
import { storeToRefs } from 'pinia'
import { reset } from '@formkit/core'
import gql from 'graphql-tag'

import { useSessionStore } from '#shared/stores/session.ts'

import CommonAlert from '#shared/components/CommonAlert/CommonAlert.vue'
import Form from '#shared/components/Form/Form.vue'
import type {
  FormSchemaNode,
  FormValues,
} from '#shared/components/Form/types.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonButtonGroup from '#desktop/components/CommonButtonGroup/CommonButtonGroup.vue'
import CommonProgressBar from '#desktop/components/CommonProgressBar/CommonProgressBar.vue'
import type { CommonButtonItem } from '#desktop/components/CommonButtonGroup/types.ts'
import CommonPopover from '#desktop/components/CommonPopover/CommonPopover.vue'
import CommonPopoverMenu from '#desktop/components/CommonPopover/CommonPopoverMenu.vue'
import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import ThemeSwitch from '#desktop/components/ThemeSwitch/ThemeSwitch.vue'
import { usePopover } from '#desktop/components/CommonPopover/usePopover.ts'
import type { ThemeSwitchInstance } from '#desktop/components/ThemeSwitch/types.ts'
import CommonDialog from '#desktop/components/CommonDialog/CommonDialog.vue'
import { useFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'
import CommonFlyout from '#desktop/components/CommonFlyout/CommonFlyout.vue'
import { useDialog } from '#desktop/components/CommonDialog/useDialog.ts'
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'
import { useConfirmation } from '#shared/composables/useConfirmation.ts'

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
  {
    label: 'Button 6',
    variant: 'subtle',
  },
  {
    label: 'Button 7',
    variant: 'neutral',
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
          help: 'Testing',
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
    type: 'autocomplete',
    name: 'autocomplete',
    label: 'Autocomplete',
    props: {
      clearable: true,
      gqlQuery: gql`
        query autocompleteSearchUser($input: AutocompleteSearchInput!) {
          autocompleteSearchUser(input: $input) {
            value
            label
            disabled
            icon
          }
        }
      `,
    },
  },
  {
    type: 'agent',
    name: 'agent',
    label: 'Agent',
    props: {
      clearable: true,
    },
  },
  {
    name: 'date_0',
    label: 'Date',
    type: 'date',
    props: {
      clearable: true,
    },
  },
  {
    name: 'date_1',
    label: 'Date range',
    type: 'date',
    props: {
      clearable: true,
      range: true,
    },
  },
  {
    name: 'datetime_0',
    label: 'Date/Time',
    type: 'datetime',
    props: {
      clearable: true,
    },
    required: true,
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
  {
    type: 'radioList',
    name: 'radioRoles',
    label: 'Radio roles',
    value: 1,
    props: {
      options: [
        { value: 3, label: 'name only' },
        { value: 33333, label: 'name onlyyyy' },
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

const formInitialValues: FormValues = {
  roles: [3, 1],
  // date_0: [new Date(), new Date(new Date().setDate(new Date().getDate() + 7))],
}

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

const { isOpen: popoverIsOpen, popover, popoverTarget, toggle } = usePopover()

const themeSwitch = ref<ThemeSwitchInstance>()

const cycleThemeSwitchValue = () => {
  themeSwitch.value?.cycleValue()
}

const appearance = ref('auto')

const schema: FormSchemaNode[] = [
  {
    type: 'text',
    name: 'code',
    label: 'Test',
    required: true,
    props: {
      help: 'Enter here something',
    },
  },
]

const flyout = useFlyout({
  name: 'playground',
  component: () =>
    new Promise((resolve) => {
      return resolve(
        h(
          CommonFlyout,
          {
            onClose: () => {
              console.log(
                '%c %s',
                'color: red; font-size: 16px',
                'Flyout closed!',
              )
            },
            onAction: () => {
              console.log(
                '%c %s',
                'color: green; font-size: 16px',
                'Flyout action!',
              )
            },
            name: 'playground',
            headerTitle: 'Hello Playground',
            persistWidth: true,
            headerIcon: 'buildings',
            footerActionOptions: {
              actionLabel: 'Submit test',
              cancelLabel: 'Adios',
              actionButton: {
                type: 'submit',
                variant: 'primary',
                prefixIcon: 'check2',
              },
            },
          },
          {
            default: () => [
              h('div', { class: 'py-1' }, [
                h('input'),
                h(Form, { ref: 'flyoutForm', schema }),
                h('div', { class: 'w-[400px]', innerHTML: 'Hello world!' }),
                h(
                  'p',
                  '    Lorem ipsum dolor sit amet, consectetur adipisicing elit. Ab laborum magnam omnis qui, ratione similique velit voluptatem. Cumque esse et, expedita inventore, iusto laboriosam magnam minus necessitatibus numquam odio odit optio quaerat, quidem quo quos reiciendis rem similique ut veniam vero. Aperiam at blanditiis dignissimos est et, ex harum id in itaque magni natus neque officia omnis perferendis quaerat, quasi ratione reiciendis sunt vitae voluptatum. At id obcaecati odio rerum sed! Accusamus aliquid assumenda cupiditate deleniti distinctio dolore dolores ea earum enim eos error esse ex expedita hic id incidunt iste laudantium molestias nisi obcaecati omnis placeat quam quibusdam quis, quod ratione rem repellendus reprehenderit sed sint soluta velit vitae voluptas voluptate voluptatem voluptates voluptatum. Delectus facilis nostrum praesentium quos sed. Ad assumenda atque cum cumque distinctio dolorem dolores excepturi explicabo harum impedit iusto labore, laboriosam laudantium libero minima nam pariatur quasi quisquam rem repellat reprehenderit saepe sapiente, tempora ut voluptates! Assumenda distinctio impedit veniam vitae voluptates! Aperiam, at commodi dignissimos ex exercitationem inventore quibusdam sequi veniam! A ab accusamus aperiam architecto atque beatae blanditiis commodi consequatur, deleniti deserunt dolor ducimus eaque ex excepturi illum incidunt ipsum laboriosam magni minus molestiae nam nesciunt nulla odit perferendis perspiciatis possimus quod quos similique sint suscipit temporibus unde veritatis voluptatibus? Ab ad, adipisci animi beatae ea eaque eligendi explicabo id impedit itaque magni mollitia nihil numquam obcaecati odit officia omnis perferendis porro quaerat quasi quod repellendus sint sunt suscipit, tenetur vel veniam. Ad animi architecto, aspernatur at blanditiis cumque delectus deleniti dolorem dolorum eos eum eveniet facilis fuga fugiat hic ipsam iure laboriosam maiores natus nisi nobis nulla officiis optio perferendis porro quaerat quam qui quo, repellat sed similique sint suscipit tenetur ullam veritatis vitae voluptates. A ad illo minima nisi nobis vitae voluptatem? Autem deleniti error maiores minus pariatur porro quidem suscipit!',
                ),
              ]),
            ],
          },
        ),
      )
    }),
})

const dialog = useDialog({
  name: 'playground',
  component: () =>
    new Promise((resolve) => {
      return resolve(
        h(CommonDialog, {
          name: 'playground',
          headerTitle: 'Confirmation',
          content: 'Do you want to continue?',
        }),
      )
    }),
})

const { waitForVariantConfirmation } = useConfirmation()
const deleteTest = async () => {
  const confirmed = await waitForVariantConfirmation('delete')

  if (confirmed) {
    console.log('Item deleted!')
  } else {
    console.log('Item not deleted!')
  }
}

const vip = ref(false)
</script>

<template>
  <LayoutContent :breadcrumb-items="[]">
    <div class="w-1/2">
      <h2 class="text-xl">Buttons</h2>

      <h3>Text only</h3>
      <div class="flex space-x-3 py-2">
        <CommonButton variant="primary" />
        <CommonButton variant="secondary" />
        <CommonButton variant="tertiary" />
        <CommonButton variant="submit" />
        <CommonButton variant="danger" />
        <CommonButton variant="subtle" />
        <CommonButton variant="neutral" />
      </div>

      <h3>With icon</h3>
      <div class="flex space-x-3 py-2">
        <CommonButton variant="primary" prefix-icon="logo-flat" />
        <CommonButton variant="secondary" prefix-icon="logo-flat" />
        <CommonButton variant="tertiary" prefix-icon="logo-flat" />
        <CommonButton variant="submit" prefix-icon="logo-flat" />
        <CommonButton variant="danger" prefix-icon="logo-flat" />
        <CommonButton variant="subtle" prefix-icon="logo-flat" />
        <CommonButton variant="neutral" prefix-icon="logo-flat" />
      </div>

      <h3>Icon only</h3>
      <div class="flex items-center space-x-3 py-2">
        <CommonButton variant="primary" icon="logo-flat" />
        <CommonButton variant="secondary" icon="logo-flat" />
        <CommonButton variant="tertiary" icon="logo-flat" />
        <CommonButton variant="submit" icon="logo-flat" />
        <CommonButton variant="danger" icon="logo-flat" />
        <CommonButton variant="subtle" icon="logo-flat" />
        <CommonButton variant="neutral" icon="logo-flat" />
        <CommonButton variant="primary" icon="logo-flat" size="medium" />
        <CommonButton variant="secondary" icon="logo-flat" size="medium" />
        <CommonButton variant="tertiary" icon="logo-flat" size="medium" />
        <CommonButton variant="submit" icon="logo-flat" size="medium" />
        <CommonButton variant="danger" icon="logo-flat" size="medium" />
        <CommonButton variant="subtle" icon="logo-flat" size="medium" />
        <CommonButton variant="neutral" icon="logo-flat" size="medium" />
        <CommonButton variant="primary" icon="logo-flat" size="large" />
        <CommonButton variant="secondary" icon="logo-flat" size="large" />
        <CommonButton variant="tertiary" icon="logo-flat" size="large" />
        <CommonButton variant="submit" icon="logo-flat" size="large" />
        <CommonButton variant="danger" icon="logo-flat" size="large" />
        <CommonButton variant="subtle" icon="logo-flat" size="large" />
        <CommonButton variant="neutral" icon="logo-flat" size="large" />
      </div>

      <h3>Misc</h3>
      <div class="flex-wrap space-x-3 space-y-2 py-2">
        <CommonButton variant="submit" block>Block</CommonButton>
        <CommonButton variant="primary" disabled>Disabled</CommonButton>
        <CommonButton variant="secondary" disabled>Disabled</CommonButton>
        <CommonButton variant="tertiary" disabled>Disabled</CommonButton>
        <CommonButton variant="submit" disabled>Disabled</CommonButton>
        <CommonButton variant="danger" disabled>Disabled</CommonButton>
        <CommonButton variant="subtle" disabled>Disabled</CommonButton>
        <CommonButton variant="neutral" disabled>Disabled</CommonButton>
      </div>

      <h3>Group</h3>
      <div class="w-1/2 space-x-3 space-y-2 py-2">
        <CommonButtonGroup :items="buttonGroupOptions" />
      </div>
    </div>

    <div class="w-1/2">
      <h2 class="text-xl">Alerts</h2>

      <CommonAlert
        variant="info"
        dismissible
        link="https://youtu.be/U6n2NcJ7rLc"
        link-text="Party 🎉"
        class="mb-2.5"
        >It's Friday!
      </CommonAlert>
      <CommonAlert variant="success" class="mb-2.5"
        >Hooray! Ticket got updated.
      </CommonAlert>
      <CommonAlert variant="warning" class="mb-2.5"
        >Heee! You're typing too fast.
      </CommonAlert>
      <CommonAlert variant="danger" class="mb-2.5"
        >Ooops! You broke it.
      </CommonAlert>
    </div>

    <div>
      <h2>Labels</h2>
      <CommonLabel size="small" prefix-icon="logo" suffix-icon="logo-flat">
        Small
      </CommonLabel>

      <br />

      <CommonLabel size="medium" prefix-icon="logo" suffix-icon="logo-flat">
        Medium
      </CommonLabel>

      <br />

      <CommonLabel size="large" prefix-icon="logo" suffix-icon="logo-flat">
        Large
      </CommonLabel>

      <br />

      <CommonLabel size="xl" prefix-icon="logo" suffix-icon="logo-flat">
        Extra large
      </CommonLabel>
    </div>

    <div>
      <h2>Badges</h2>

      <CommonBadge class="ltr:mr-2 rtl:ml-2" variant="neutral">
        Neutral
      </CommonBadge>

      <CommonBadge class="ltr:mr-2 rtl:ml-2" variant="info">Info</CommonBadge>

      <CommonBadge class="ltr:mr-2 rtl:ml-2" variant="success">
        Success
      </CommonBadge>

      <CommonBadge class="ltr:mr-2 rtl:ml-2" variant="warning">
        Warning
      </CommonBadge>

      <CommonBadge class="ltr:mr-2 rtl:ml-2" variant="danger">
        Danger
      </CommonBadge>

      <CommonBadge
        class="bg-pink-300 text-white ltr:mr-2 rtl:ml-2 dark:bg-pink-300"
        variant="custom"
        >Custom
      </CommonBadge>
    </div>

    <div class="w-1/5">
      <h2>Progress Bar</h2>

      <div class="flex flex-col gap-3">
        <div class="flex flex-col gap-2">
          <CommonLabel size="small">What is the meaning of life?</CommonLabel>
          <CommonProgressBar />
        </div>

        <div class="flex items-end gap-2">
          <div class="mb-1 flex grow flex-col gap-1">
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

    <div class="w-1/2">
      <h2 class="text-lg">Avatar</h2>

      <div class="my-4 flex items-center gap-4">
        <CommonUserAvatar
          class="cursor-pointer border border-neutral-100 outline outline-2 outline-transparent hover:outline-blue-600 focus:outline-blue-800 dark:border-gray-900 dark:hover:outline-blue-900 dark:hover:focus:outline-blue-800"
          tabindex="0"
          :entity="{
            id: 'gid://zammad/User/1',
            vip,
          }"
          size="medium"
        />

        <CommonButton :variant="vip ? 'neutral' : 'subtle'" @click="vip = !vip">
          {{ vip ? 'Make us unimportant :(' : 'Make us important :)' }}
        </CommonButton>
      </div>

      <div class="flex gap-4">
        <CommonUserAvatar
          class="cursor-pointer border border-neutral-100 outline outline-2 outline-transparent hover:outline-blue-600 focus:outline-blue-800 dark:border-gray-900 dark:hover:outline-blue-900 dark:hover:focus:outline-blue-800"
          tabindex="0"
          :entity="{
            id: 'gid://zammad/User/2',
            firstname: 'Alfa',
            lastname: 'Bravo',
            vip,
          }"
          size="xs"
        />
        <CommonUserAvatar
          class="cursor-pointer border border-neutral-100 outline outline-2 outline-transparent hover:outline-blue-600 focus:outline-blue-800 dark:border-gray-900 dark:hover:outline-blue-900 dark:hover:focus:outline-blue-800"
          tabindex="0"
          :entity="{
            id: 'gid://zammad/User/3',
            firstname: 'Charlie',
            lastname: 'Delta',
            vip,
          }"
          size="small"
        />
        <CommonUserAvatar
          class="cursor-pointer border border-neutral-100 outline outline-2 outline-transparent hover:outline-blue-600 focus:outline-blue-800 dark:border-gray-900 dark:hover:outline-blue-900 dark:hover:focus:outline-blue-800"
          tabindex="0"
          :entity="{
            id: 'gid://zammad/User/4',
            firstname: 'Echo',
            lastname: 'Foxtrot',
            vip,
          }"
          size="medium"
        />
        <CommonUserAvatar
          class="cursor-pointer outline outline-2 outline-transparent hover:outline-blue-600 focus:outline-blue-800 dark:hover:outline-blue-900 dark:hover:focus:outline-blue-800"
          tabindex="0"
          :entity="{
            id: 'gid://zammad/User/5',
            firstname: 'Golf',
            lastname: 'Hotel',
            vip,
          }"
          size="normal"
        />
        <CommonUserAvatar
          class="cursor-pointer border border-neutral-100 outline outline-2 outline-transparent hover:outline-blue-600 focus:outline-blue-800 dark:border-gray-900 dark:hover:outline-blue-900 dark:hover:focus:outline-blue-800"
          tabindex="0"
          :entity="{
            id: 'gid://zammad/User/6',
            firstname: 'India',
            lastname: 'Juliett',
            vip,
          }"
          size="large"
        />
        <CommonUserAvatar
          class="cursor-pointer border border-neutral-100 outline outline-2 outline-transparent hover:outline-blue-600 focus:outline-blue-800 dark:border-gray-900 dark:hover:outline-blue-900 dark:hover:focus:outline-blue-800"
          tabindex="0"
          :entity="{
            id: 'gid://zammad/User/7',
            firstname: 'Kilo',
            lastname: 'Lima',
            vip,
          }"
          size="xl"
        />
      </div>
    </div>

    <div>
      <h2 class="text-lg">Popover</h2>

      <template v-if="user">
        <CommonPopover
          ref="popover"
          :owner="popoverTarget"
          orientation="autoVertical"
          placement="start"
        >
          <CommonPopoverMenu
            :popover="popover"
            header-label="Erika Mustermann"
            :items="[
              {
                key: 'appearance',
                label: 'Appearance',
                icon: 'brightness-alt-high',
                noCloseOnClick: true,
                onClick: cycleThemeSwitchValue,
              },
              {
                key: 'keyboard-shortcuts',
                label: 'Keyboard shortcuts',
                onClick: () => {
                  console.log('OPEN KEYBOARD SHORTCUTS DIALOG')
                },
                icon: 'keyboard',
              },
              {
                key: 'personal-setting',
                label: 'Profile settings',
                link: '/personal-setting',
                icon: 'person-gear',
              },
              {
                key: 'sign-out',
                label: 'Sign out',
                link: '/logout',
                icon: 'box-arrow-in-right',
                separatorTop: true,
              },
            ]"
          >
            <template #itemRight-appearance>
              <div class="flex items-center px-2">
                <ThemeSwitch
                  ref="themeSwitch"
                  v-model="appearance"
                  size="small"
                />
              </div>
            </template>
          </CommonPopoverMenu>
        </CommonPopover>
        <button
          ref="popoverTarget"
          class="-:outline-transparent hover:-:outline-blue-900 rounded-full outline outline-2 focus:outline-blue-800 hover:focus:outline-blue-800"
          :class="{
            'outline-blue-800 hover:outline-blue-800': popoverIsOpen,
          }"
          @click="toggle(true)"
        >
          <CommonUserAvatar :entity="user" size="large" personal />
        </button>
      </template>
    </div>

    <h2 class="mb-2 mt-8">Flyout and Dialog</h2>
    <div class="mb-6 flex gap-4">
      <CommonButton variant="tertiary" @click="dialog.open()"
        >Show Dialog
      </CommonButton>
      <CommonButton variant="primary" @click="flyout.open()">
        Open Flyout
      </CommonButton>
    </div>

    <h2 class="mb-2">Confirmation</h2>
    <div class="mb-6 flex gap-4">
      <CommonButton variant="tertiary" @click="deleteTest()"
        >Delete
      </CommonButton>
    </div>

    <div class="w-1/2">
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
          <div class="mt-5 flex items-center justify-end gap-2">
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
  </LayoutContent>
</template>
