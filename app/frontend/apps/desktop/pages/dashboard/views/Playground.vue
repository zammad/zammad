<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->
<!-- eslint-disable zammad/zammad-detect-translatable-string -->

<script setup lang="ts">
import { reset } from '@formkit/core'
import gql from 'graphql-tag'
import { storeToRefs } from 'pinia'
import {
  computed,
  h,
  onMounted,
  reactive,
  ref,
  watch,
  type Ref,
  useTemplateRef,
} from 'vue'

import CommonAlert from '#shared/components/CommonAlert/CommonAlert.vue'
import CommonPopover from '#shared/components/CommonPopover/CommonPopover.vue'
import type {
  Orientation,
  Placement,
} from '#shared/components/CommonPopover/types.ts'
import { usePopover } from '#shared/components/CommonPopover/usePopover.ts'
import CommonTranslateRenderer from '#shared/components/CommonTranslateRenderer/CommonTranslateRenderer.vue'
import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import Form from '#shared/components/Form/Form.vue'
import type {
  FormSchemaNode,
  FormValues,
} from '#shared/components/Form/types.ts'
import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import { useCopyToClipboard } from '#shared/composables/useCopyToClipboard.ts'
import { defineFormSchema } from '#shared/form/defineFormSchema.ts'
import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import CommonActionMenu from '#desktop/components/CommonActionMenu/CommonActionMenu.vue'
import CommonBreadcrumb from '#desktop/components/CommonBreadcrumb/CommonBreadcrumb.vue'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonButtonGroup from '#desktop/components/CommonButtonGroup/CommonButtonGroup.vue'
import type { CommonButtonItem } from '#desktop/components/CommonButtonGroup/types.ts'
import CommonDialog from '#desktop/components/CommonDialog/CommonDialog.vue'
import { useDialog } from '#desktop/components/CommonDialog/useDialog.ts'
import CommonFlyout from '#desktop/components/CommonFlyout/CommonFlyout.vue'
import { useFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'
import CommonInlineEdit from '#desktop/components/CommonInlineEdit/CommonInlineEdit.vue'
import CommonInputCopyToClipboard from '#desktop/components/CommonInputCopyToClipboard/CommonInputCopyToClipboard.vue'
import CommonPopoverMenu from '#desktop/components/CommonPopoverMenu/CommonPopoverMenu.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import CommonProgressBar from '#desktop/components/CommonProgressBar/CommonProgressBar.vue'
import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'
import CommonTabGroup from '#desktop/components/CommonTabGroup/CommonTabGroup.vue'
import { useTabGroup } from '#desktop/components/CommonTabGroup/useTabGroup.ts'
import CommonAdvancedTable from '#desktop/components/CommonTable/CommonAdvancedTable.vue'
import CommonSimpleTable from '#desktop/components/CommonTable/CommonSimpleTable.vue'
import CommonTableSkeleton from '#desktop/components/CommonTable/Skeleton/CommonTableSkeleton.vue'
import type { TableAdvancedItem } from '#desktop/components/CommonTable/types.ts'
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'
import SplitButton from '#desktop/components/SplitButton/SplitButton.vue'
import ThemeSwitch from '#desktop/components/ThemeSwitch/ThemeSwitch.vue'

const alphabetOptions = computed(() =>
  [...Array(26).keys()].map((i) => ({
    value: i,
    label: `Item ${String.fromCharCode(65 + i)}`,
    disabled: Math.random() < 0.5,
  })),
)

const { copyToClipboard } = useCopyToClipboard()

const longOption = ref({
  value: 999,
  label:
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, nullam pulvinar nunc sapien, vitae malesuada justo interdum feugiat, mauris odio, mattis et malesuada quis, vulputate vitae enim',
})

const permissions = [
  {
    value: 'admin',
    label: 'Admin interface',
    description: 'To configure your system.',
    children: [
      {
        value: 'admin.user',
        label: 'Users',
        description: 'To manage all users of your system.',
      },
      {
        value: 'admin.group',
        label: 'Groups',
        description: 'To manage groups of your system.',
      },
      {
        value: 'admin.role',
        label: 'Roles',
        description: 'To manage roles of your system.',
      },
      {
        value: 'admin.organization',
        label: 'Organizations',
        description: 'To manage all organizations of your system.',
      },
      {
        value: 'admin.overview',
        label: 'Overviews',
        description: 'To manage ticket overviews of your system.',
      },
      {
        value: 'admin.text_module',
        label: 'Text modules',
        description: 'To manage text modules of your system.',
      },
      {
        value: 'admin.macro',
        label: 'Macros',
        description: 'To manage ticket macros of your system.',
      },
      {
        value: 'admin.template',
        label: 'Templates',
        description: 'To manage ticket templates of your system.',
      },
      {
        value: 'admin.tag',
        label: 'Tags',
        description: 'To manage ticket tags of your system.',
      },
      {
        value: 'admin.calendar',
        label: 'Calendar',
        description: 'To manage calendars of your system.',
      },
      {
        value: 'admin.sla',
        label: 'SLAs',
        description: 'To manage Service Level Agreements of your system.',
      },
      {
        value: 'admin.trigger',
        label: 'Trigger',
        description: 'To manage triggers of your system.',
      },
      {
        value: 'admin.public_links',
        label: 'Public Links',
        description: 'To manage public links of your system.',
      },
      {
        value: 'admin.webhook',
        label: 'Webhook',
        description: 'To manage webhooks of your system.',
      },
      {
        value: 'admin.scheduler',
        label: 'Scheduler',
        description: 'To manage schedulers of your system.',
      },
      {
        value: 'admin.report_profile',
        label: 'Report Profiles',
        description: 'To manage report profiles of your system.',
      },
      {
        value: 'admin.time_accounting',
        label: 'Time Accounting',
        description: 'To manage time accounting settings of your system.',
      },
      {
        value: 'admin.knowledge_base',
        label: 'Knowledge Base',
        description: 'To create and set up Knowledge Base.',
      },
      {
        value: 'admin.channel_web',
        label: 'Web',
        description: 'To manage web channel of your system.',
      },
      {
        value: 'admin.channel_formular',
        label: 'Form',
        description: 'To manage form channel of your system.',
      },
      {
        value: 'admin.channel_email',
        label: 'Email',
        description: 'To manage email channel of your system.',
      },
      {
        value: 'admin.channel_sms',
        label: 'SMS',
        description: 'To manage SMS channel of your system.',
      },
      {
        value: 'admin.channel_chat',
        label: 'Chat',
        description: 'To manage chat channel of your system.',
      },
      {
        value: 'admin.channel_google',
        label: 'Google',
        description: 'To manage Google channel of your system.',
      },
      {
        value: 'admin.channel_microsoft365',
        label: ' Microsoft 365',
        description: 'To manage Microsoft 365 channel of your system.',
      },
      {
        value: 'admin.channel_microsoft_graph',
        label: ' Microsoft Graph',
        description: 'To manage Microsoft Graph channel of your system.',
      },
      {
        value: 'admin.channel_twitter',
        label: 'Twitter',
        description: 'To manage Twitter channel of your system.',
      },
      {
        value: 'admin.channel_facebook',
        label: 'Facebook',
        description: 'To manage Facebook channel of your system.',
      },
      {
        value: 'admin.channel_telegram',
        label: 'Telegram',
        description: 'To manage Telegram channel of your system.',
      },
      {
        value: 'admin.channel_whatsapp',
        label: 'WhatsApp',
        description: 'To manage WhatsApp channel of your system.',
      },
      {
        value: 'admin.branding',
        label: 'Branding',
        description: 'To manage branding settings of your system.',
      },
      {
        value: 'admin.setting_system',
        label: 'System',
        description: 'To manage core system settings.',
      },
      {
        value: 'admin.security',
        label: 'Security',
        description: 'To manage security settings of your system.',
      },
      {
        value: 'admin.ticket',
        label: 'Ticket',
        description: 'To manage ticket settings of your system.',
      },
      {
        value: 'admin.integration',
        label: 'Integrations',
        description: 'To manage integrations of your system.',
      },
      {
        value: 'admin.api',
        label: 'API',
        description: 'To manage API of your system.',
      },
      {
        value: 'admin.object',
        label: 'Objects',
        description: 'To manage object attributes of your system.',
      },
      {
        value: 'admin.ticket_state',
        label: 'Ticket States',
        description: 'To manage ticket states of your system.',
      },
      {
        value: 'admin.ticket_priority',
        label: 'Ticket Priorities',
        description: 'To manage ticket priorities of your system.',
      },
      {
        value: 'admin.core_workflow',
        label: 'Core Workflows',
        description: 'To manage core workflows of your system.',
      },
      {
        value: 'admin.translation',
        label: 'Translations',
        description: 'To manage translations of your system.',
      },
      {
        value: 'admin.data_privacy',
        label: 'Data Privacy',
        description: 'To delete existing data of your system.',
      },
      {
        value: 'admin.maintenance',
        label: 'Maintenance',
        description: 'To manage maintenance mode of your system.',
      },
      {
        value: 'admin.monitoring',
        label: 'Monitoring',
        description: 'To manage monitoring of your system.',
      },
      {
        value: 'admin.package',
        label: 'Packages',
        description: 'To manage packages of your system.',
      },

      {
        value: 'admin.session',
        label: 'Sessions',
        description: 'To manage active user sessions of your system.',
      },
      {
        value: 'admin.system_report',
        label: 'System Report',
        description: 'To manage system report of your system.',
      },
    ],
  },
  {
    value: 'chat',
    label: 'Chat',
    description: 'To access the chat interface.',
    disabled: true,
    children: [
      {
        value: 'chat.agent',
        label: 'Agent Chat',
        description: 'To access the agent chat features.',
      },
    ],
  },
  {
    value: 'cti',
    label: 'Phone',
    description: 'To access the phone interface.',
    disabled: true,
    children: [
      {
        value: 'cti.agent',
        label: 'Agent Phone',
        description: 'To access the agent phone features.',
      },
    ],
  },
  {
    value: 'knowledge_base',
    label: 'Knowledge Base',
    description: 'To access the knowledge base interface.',
    disabled: true,
    children: [
      {
        value: 'knowledge_base.editor',
        label: 'Knowledge Base Editor',
        description: 'To access the knowledge base editor features.',
      },
      {
        value: 'knowledge_base.reader',
        label: 'Knowledge Base Reader',
        description: 'To access the knowledge base reader features.',
      },
    ],
  },
  {
    value: 'report',
    label: 'Report',
    description: 'To access the report interface.',
  },
  {
    value: 'ticket',
    label: 'Ticket',
    description: 'To access the ticket interface.',
    disabled: true,
    children: [
      {
        value: 'ticket.agent',
        label: 'Agent Tickets',
        description: 'To access the agent tickets based on group access.',
      },
      {
        value: 'ticket.customer',
        label: 'Customer Tickets',
        description: 'To access the customer tickets.',
      },
    ],
  },
  {
    value: 'user_preferences',
    label: 'Profile settings',
    description: 'To access the personal settings.',
    children: [
      {
        value: 'user_preferences.appearance',
        label: 'Appearance',
        description: 'To access the appearance personal setting.',
      },
      {
        value: 'user_preferences.language',
        label: 'Language',
        description: 'To access the language personal setting.',
      },
      {
        value: 'user_preferences.avatar',
        label: 'Avatar',
        description: 'To access the avatar personal setting.',
      },
      {
        value: 'user_preferences.out_of_office',
        label: 'Out of Office',
        description: 'To access the out of office personal setting.',
      },
      {
        value: 'user_preferences.password',
        label: 'Password',
        description: 'To access the change password personal setting.',
      },
      {
        value: 'user_preferences.two_factor_authentication',
        label: 'Two-factor Authentication',
        description:
          'To access the two-factor authentication personal setting.',
      },
      {
        value: 'user_preferences.device',
        label: 'Devices',
        description: 'To access the devices personal setting.',
      },
      {
        value: 'user_preferences.access_token',
        label: 'Token Access',
        description: 'To access the API token personal setting.',
      },
      {
        value: 'user_preferences.linked_accounts',
        label: 'Linked Accounts',
        description: 'To access the linked accounts personal setting.',
      },
      {
        value: 'user_preferences.notifications',
        label: 'Notifications',
        description: 'To access the notifications personal setting.',
      },
      {
        value: 'user_preferences.overview_sorting',
        label: 'Overviews',
        description: 'To access the overviews personal setting.',
      },
      {
        value: 'user_preferences.calendar',
        label: 'Calendar',
        description: 'To access the calendar personal setting.',
      },
    ],
  },
]

const treeselectOptions = [
  {
    value: 0,
    label: 'Item A',
    disabled: true,
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

const application = useApplicationStore()

const formSchema = defineFormSchema([
  {
    type: 'editor',
    name: 'editor',
    label: 'Editor',
    required: true,
  },
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
    type: 'security',
    name: 'security',
    label: 'Security',
    props: {
      securityAllowed: {
        SMIME: [],
        PGP: ['sign', 'encryption'],
      },
      securityDefaultOptions: {
        SMIME: ['sign', 'encryption'],
        PGP: ['sign'],
      },
      securityMessages: {
        SMIME: {
          sign: {
            message: 'The certificate for %s was not found.',
            messagePlaceholder: ['zammad@localhost'],
          },
          encryption: {
            message: 'The certificates for %s were not found.',
            messagePlaceholder: ['nicole.braun@zammad.org'],
          },
        },
        PGP: {
          sign: {
            message: 'The PGP key for %s was found.',
            messagePlaceholder: ['zammad@localhost'],
          },
          encryption: {
            message: 'The PGP keys for %s were found.',
            messagePlaceholder: ['nicole.braun@zammad.org'],
          },
        },
      },
    },
    value: { method: 'SMIME', options: [] },
  },
  {
    type: 'permissions',
    name: 'permissions',
    label: 'Permissions',
    props: {
      options: permissions,
    },
    value: ['ticket.agent'],
  },
  {
    type: 'autocomplete',
    name: 'autocomplete',
    label: 'Autocomplete',
    props: {
      clearable: true,
      gqlQuery: gql`
        query autocompleteSearchUser($input: AutocompleteSearchUserInput!) {
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
    type: 'externalDataSource',
    name: 'external_data_source',
    label: 'External Data Source',
    object: EnumObjectManagerObjects.Ticket,
    help: 'Please add external_data_source attribute on Ticket object. Otherwise this field will not work.',
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
    type: 'ticket',
    name: 'ticket',
    label: 'Ticket',
    props: {
      clearable: true,
    },
  },
  {
    type: 'recipient',
    name: 'recipient',
    label: 'Recipient',
    props: {
      clearable: true,
    },
  },
  {
    type: 'recipient',
    name: 'recipient_multiple',
    label: 'Recipient (multiple)',
    props: {
      clearable: true,
      multiple: true,
    },
  },
  {
    type: 'customer',
    name: 'customer',
    label: 'Customer',
    props: {
      clearable: true,
      link: '/',
      linkIcon: 'person-add',
    },
  },
  {
    type: 'organization',
    name: 'organization',
    label: 'Organization',
    props: {
      clearable: true,
      options: [
        {
          value: 1,
          label: 'Zammad Foundation',
          organization: {
            active: true,
          },
        },
      ],
    },
  },
  {
    type: 'tags',
    name: 'tags',
    label: 'Tags',
    props: {
      clearable: true,
      canCreate: application.config.tag_new,
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
    props: {
      options: [...alphabetOptions.value, ...[longOption.value]],
      clearable: true,
    },
  },
  {
    type: 'select',
    name: 'select_2',
    label: 'Multi select',
    props: {
      multiple: true,
      options: [...alphabetOptions.value, ...[longOption.value]],
      clearable: true,
    },
  },
  {
    type: 'treeselect',
    name: 'treeselect_1',
    label: 'Single treeselect',
    props: {
      options: treeselectOptions,
      clearable: true,
    },
  },
  {
    type: 'treeselect',
    name: 'treeselect_2',
    label: 'Multi treeselect',
    props: {
      multiple: true,
      options: treeselectOptions,
      clearable: true,
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

  {
    type: 'file',
    name: 'file',
    label: 'Attachment',
    props: {
      multiple: true,
    },
  },
  {
    type: 'toggleButtons',
    name: 'toggleButtons',
    label: 'Toggle Buttons',
    value: '1',
    props: {
      options: [
        { value: '3', label: 'name only' },
        { value: '33333', label: 'name onlyyyy' },
        { value: '1', label: 'Long name', icon: 'sun' },
      ],
    },
  },
])

const formValues = ref()

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

const themeSwitchInstance = useTemplateRef('theme-switch')

const cycleThemeSwitchValue = () => {
  themeSwitchInstance.value?.cycleValue()
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

const tableHeaders = [
  {
    key: 'name',
    label: 'User name',
  },
  {
    key: 'title',
    label: 'Job position',
    truncate: true,
  },
  {
    key: 'email',
    label: 'Email',
  },
  {
    key: 'role',
    label: 'Role',
  },
]

const tableHeadersAdvanced = ['name', 'title', 'email', 'role']

const tableItems = reactive([
  {
    id: 1,
    name: 'Lindsay Walton',
    title: 'Front-end Developer',
    email: 'lindsay.walton@example.com',
    role: 'Member',
    checked: true,
  },
  {
    id: 2,
    name: 'Courtney Henry',
    title: 'Designer',
    email: 'courtney.henry@example.com',
    role: 'Admin',
  },
  {
    id: 3,
    name: 'Tom Cook',
    title: 'Director of Product',
    email: 'tom.cook@example.com',
    role: 'Member',
  },
  {
    id: 4,
    name: 'Whitney Francis',
    title: 'Copywriter',
    email: 'whitney.francis@example.com',
    role: 'Admin',
  },
  {
    id: 5,
    name: 'Leonard Krasner',
    title: 'Senior Designer Principal Designer ',
    email: 'leonard.krasner@example.com',
    role: 'Owner',
  },
  {
    id: 6,
    name: 'Floyd Miles',
    title:
      'Principal Designer for a very long way to go to see the end of the title. It is a very long title, indeed.',
    email: 'floyd.miles@example.com',
    role: 'Member',
  },
  {
    id: 7,
    name: 'Floyd Miles2',
    title:
      'Principal Designer for a very long way to go to see the end of the title. It is a very long title, indeed.',
    email: 'floyd.miles@example.com',
    role: 'Member',
  },
  {
    id: 8,
    name: 'Floyd Miles3',
    title:
      'Principal Designer for a very long way to go to see the end of the title. It is a very long title, indeed.',
    email: 'floyd.miles@example.com',
    role: 'Member',
  },
  {
    id: 9,
    name: 'Floyd Miles4',
    title:
      'Principal Designer for a very long way to go to see the end of the title. It is a very long title, indeed.',
    email: 'floyd.miles@example.com',
    role: 'Member',
  },
  {
    id: 10,
    name: 'Floyd Miles5',
    title:
      'Principal Designer for a very long way to go to see the end of the title. It is a very long title, indeed.',
    email: 'floyd.miles@example.com',
    role: 'Member',
  },
])

const tableItemsAdvanced = reactive<TableAdvancedItem[]>([
  {
    id: '1',
    name: 'Lindsay Walton',
    title: 'Front-end Developer',
    email: 'lindsay.walton@example.com',
    role: 'Member',
  },
  {
    id: '2',
    name: 'Courtney Henry',
    title: 'Designer',
    email: 'courtney.henry@example.com',
    role: 'Admin',
  },
  {
    id: '3',
    name: 'Tom Cook',
    title: 'Director of Product',
    email: 'tom.cook@example.com',
    role: 'Member',
  },
  {
    id: '4',
    name: 'Whitney Francis',
    title: 'Copywriter',
    email: 'whitney.francis@example.com',
    role: 'Admin',
  },
  {
    id: '5',
    name: 'Leonard Krasner',
    title: 'Senior Designer Principal Designer ',
    email: 'leonard.krasner@example.com',
    role: 'Owner',
  },
  {
    id: '6',
    name: 'Floyd Miles',
    title:
      'Principal Designer for a very long way to go to see the end of the title. It is a very long title, indeed.',
    email: 'floyd.miles@example.com',
    role: 'Member',
  },
  {
    id: '7',
    name: 'Floyd Miles2',
    title:
      'Principal Designer for a very long way to go to see the end of the title. It is a very long title, indeed.',
    email: 'floyd.miles@example.com',
    role: 'Member',
  },
  {
    id: '8',
    name: 'Floyd Miles3',
    title:
      'Principal Designer for a very long way to go to see the end of the title. It is a very long title, indeed.',
    email: 'floyd.miles@example.com',
    role: 'Member',
  },
  {
    id: '9',
    name: 'Floyd Miles4',
    title:
      'Principal Designer for a very long way to go to see the end of the title. It is a very long title, indeed.',
    email: 'floyd.miles@example.com',
    role: 'Member',
  },
  {
    id: '10',
    name: 'Floyd Miles5',
    title:
      'Principal Designer for a very long way to go to see the end of the title. It is a very long title, indeed.',
    email: 'floyd.miles@example.com',
    role: 'Member',
  },
])

const tableItemsMap = new Set(['1', '2'])
const checkedAdvancedTableItems = ref(tableItemsMap)

const tableActions: MenuItem[] = [
  {
    key: 'delete',
    label: 'Delete this row',
    icon: 'trash3',
    show: (data) => !!data?.role,
    onClick: (data) => {
      console.log(data)
    },
  },
  {
    key: 'download',
    label: 'Download this row',
    icon: 'download',
    onClick: (data) => {
      console.log(data)
    },
  },
]

const changeRowSimple = () => {
  tableItems[0].role = tableItems[0].role ? '' : 'Member'
}

const { activeTab } = useTabGroup<string>()

const { activeTab: activeFilters } = useTabGroup<string[]>()

const popoverOrientation: Ref<Orientation> = ref('autoVertical')
const popoverOrientationOptions = [
  {
    value: 'autoVertical',
    label: 'Auto vertical',
  },
  {
    value: 'autoHorizontal',
    label: 'Auto horizontal',
  },
  {
    value: 'top',
    label: 'Top',
  },
  {
    value: 'bottom',
    label: 'Bottom',
  },
  {
    value: 'left',
    label: 'Left',
  },
  {
    value: 'right',
    label: 'Right',
  },
]

const popoverPlacement: Ref<Placement> = ref('start')
const popoverPlacementOptions = [
  {
    value: 'start',
    label: 'Start',
  },
  {
    value: 'arrowStart',
    label: 'Arrow Start',
  },
  {
    value: 'arrowEnd',
    label: 'Arrow End',
  },
  {
    value: 'end',
    label: 'End',
  },
]

const breadcrumbItems = [
  {
    label: 'Tickets',
    icon: 'logo-flat',
  },
  {
    label: '123456',
    route: 'tickets/1',
  },
]

const popoverHideArrow = ref(false)

const inlineEditValue = ref('Edit me inline')

const splitButtonMenuItems: MenuItem[] = [
  {
    label: 'Save as draft',
    groupLabel: 'Drafts',
    icon: 'floppy',
    key: 'save-draft',
    onClick: () => {
      console.log('Save as draft clicked!')
    },
  },
  {
    label: 'Macro 1',
    groupLabel: 'Macros',
    icon: 'play-circle',
    iconClass: 'text-yellow-300',
    key: 'macro-1',
    onClick: () => {
      console.log('Macro 1 clicked!')
    },
  },
  {
    label: 'Macro 2',
    groupLabel: 'Macros',
    icon: 'play-circle',
    iconClass: 'text-yellow-300',
    key: 'macro-2',
    onClick: () => {
      console.log('Macro 2 clicked!')
    },
  },
  {
    label: 'Macro 3',
    groupLabel: 'Macros',
    icon: 'play-circle',
    iconClass: 'text-yellow-300',
    key: 'macro-3',
    onClick: () => {
      console.log('Macro 3 clicked!')
    },
  },
]

const onSplitButtonClick = () => {
  console.log('Split button clicked!')
}
</script>

<template>
  <LayoutContent>
    <div>
      Generic skeleton
      <CommonSkeleton class="h-8 w-full" />

      Avatar example
      <CommonSkeleton rounded class="h-8 w-8" />

      Table Skeleton
      <CommonTableSkeleton />

      <div class="w-1/2">
        <div class="flex space-x-3 py-2">
          <CommonTranslateRenderer
            source="A %s for advanced %s here. Inside a translation string: %s"
            :placeholders="[
              'test',
              {
                type: 'link',
                props: { link: 'https://www.google.com' },
                content: 'Link',
              },

              {
                type: 'link',
                props: { link: 'https://www.google.com' },
                content: 'Example',
              },
            ]"
          />
        </div>
        <h1 id="test" v-tooltip="'Hello world'" class="w-fit">
          Tooltip example
        </h1>

        <h2 title="Buttons" class="text-xl">Buttons</h2>

        <h3 v-tooltip="'another example'">Text only</h3>
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
        <div class="flex-wrap space-y-2 space-x-3 py-2">
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
        <div class="w-1/2 space-y-2 space-x-3 py-2">
          <CommonButtonGroup :items="buttonGroupOptions" />
        </div>
      </div>

      <div class="flex">
        <CommonBreadcrumb class="grow" :items="breadcrumbItems">
          <template #trailing>
            <CommonIcon
              name="files"
              size="xs"
              class="text-blue-800"
              @click="copyToClipboard('123456')"
            />
          </template>
        </CommonBreadcrumb>
      </div>

      <div class="w-1/2">
        <h2 class="text-xl">Alerts</h2>

        <CommonAlert variant="info" dismissible class="mb-2.5"
          >It's Friday!
        </CommonAlert>
        <CommonAlert variant="success" class="mb-2.5">
          <div class="flex flex-col gap-1.5">
            <CommonLabel class="text-yellow-600!" size="large"
              >Similar tickets found</CommonLabel
            >
            <CommonLabel class="text-yellow-600!"
              >Tickets with the same attributes were found.</CommonLabel
            >
            <ul class="list-inside list-disc">
              <li>31001 Test Ticket</li>
            </ul>
          </div>
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

              <CommonProgressBar
                :value="progressBarValue.toString()"
                max="100"
              />
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

      <h2 class="mt-8 mb-2">Table (Simple)</h2>
      <div class="mb-6 flex flex-col gap-4">
        <CommonButton variant="primary" @click="changeRowSimple()"
          >Change row</CommonButton
        >
        <CommonSimpleTable
          caption="test"
          :headers="tableHeaders"
          :items="tableItems"
          :actions="tableActions"
        ></CommonSimpleTable>
      </div>

      <h2 class="mt-8 mb-2">Table (Advanced)</h2>
      <div class="mb-6 flex flex-col gap-4">
        <CommonAdvancedTable
          v-model:checked-item-ids="checkedAdvancedTableItems"
          :headers="tableHeadersAdvanced"
          :items="tableItemsAdvanced"
          :actions="tableActions"
          :max-items="5"
          :total-items="10"
          has-checkbox-column
          caption="test advanced table"
          table-id="2"
          :attributes="[
            {
              name: 'name',
              label: 'Name',
              headerPreferences: {
                noResize: false,
                hideLabel: false,
                displayWidth: 200,
              },
              columnPreferences: {
                alignContent: 'left',
              },
              dataType: 'integer',
            },
            {
              name: 'title',
              label: 'Title',
              headerPreferences: {
                noResize: false,
                hideLabel: false,
                displayWidth: 200,
              },
              columnPreferences: {
                alignContent: 'center',
              },
              dataType: 'integer',
            },
            {
              name: 'email',
              label: 'Email',
              headerPreferences: {
                noResize: false,
                hideLabel: false,
                displayWidth: 200,
              },
              columnPreferences: {
                alignContent: 'right',
              },
              dataType: 'integer',
            },
            {
              name: 'role',
              label: 'Role',
              headerPreferences: {
                noResize: false,
                hideLabel: false,
                displayWidth: 200,
              },
              columnPreferences: {
                alignContent: 'left',
              },
              dataType: 'integer',
            },
          ]"
        />
      </div>

      {{ checkedAdvancedTableItems }}

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

          <CommonButton
            :variant="vip ? 'neutral' : 'subtle'"
            @click="vip = !vip"
          >
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
            class="cursor-pointer border border-neutral-100 outline-2 outline-transparent hover:outline-blue-600 focus:outline-blue-800 dark:border-gray-900 dark:hover:outline-blue-900 dark:hover:focus:outline-blue-800"
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
            class="cursor-pointer outline-2 outline-transparent hover:outline-blue-600 focus:outline-blue-800 dark:hover:outline-blue-900 dark:hover:focus:outline-blue-800"
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
            class="cursor-pointer border border-neutral-100 outline-2 outline-transparent hover:outline-blue-600 focus:outline-blue-800 dark:border-gray-900 dark:hover:outline-blue-900 dark:hover:focus:outline-blue-800"
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
            class="cursor-pointer border border-neutral-100 outline-2 outline-transparent hover:outline-blue-600 focus:outline-blue-800 dark:border-gray-900 dark:hover:outline-blue-900 dark:hover:focus:outline-blue-800"
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

        <div class="mb-2 flex gap-2">
          <FormKit
            v-model="popoverOrientation"
            type="select"
            name="orientation"
            :options="popoverOrientationOptions"
          />
          <FormKit
            v-model="popoverPlacement"
            type="select"
            name="placement"
            :options="popoverPlacementOptions"
          />
          <FormKit
            v-model="popoverHideArrow"
            type="toggle"
            name="placement"
            label="Hide arrow"
            :variants="{ true: 'yes', false: 'no' }"
          />
        </div>

        <template v-if="user">
          <CommonPopover
            ref="popover"
            :owner="popoverTarget"
            :orientation="popoverOrientation"
            :placement="popoverPlacement"
            :hide-arrow="popoverHideArrow"
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
                    ref="theme-switch"
                    v-model="appearance"
                    size="small"
                  />
                </div>
              </template>
            </CommonPopoverMenu>
          </CommonPopover>
          <button
            ref="popoverTarget"
            class="rounded-full outline-2 outline-transparent hover:outline-blue-900 focus:outline-blue-800 hover:focus:outline-blue-800"
            :class="{
              'outline-blue-800 hover:outline-blue-800': popoverIsOpen,
            }"
            @click="toggle(true)"
          >
            <CommonUserAvatar :entity="user" size="large" personal />
          </button>
        </template>
      </div>

      <section>
        <h2>Common Action Menu</h2>
        <CommonActionMenu
          :entity="{ id: 'test-me', name: 'playground' }"
          :actions="[
            {
              key: 'delete-customer',
              label: 'Delete Customer',
              variant: 'danger',
              icon: 'trash3',
              onClick: (data) => {
                console.log(data?.id, data?.name, 'Delete customer')
              },
            },
            {
              key: 'change-customer',
              label: 'Change Customer',
              icon: 'person-gear',
              onClick: (data) => {
                console.log(data?.id, data?.name, 'Change customer')
              },
            },
          ]"
        />
        <h3>Single Action Item</h3>
        <CommonActionMenu
          :entity="{ id: 'test-me', name: 'playground' }"
          :actions="[
            {
              key: 'change-customer',
              label: 'Change Customer',
              icon: 'person-gear',
              onClick: (id) => {
                console.log(id, 'Delete customer')
              },
            },
          ]"
        />
      </section>

      <div>
        <span> Inline Edit </span>
        <CommonInlineEdit
          id="test"
          :value="inlineEditValue"
          @submit-edit="
            (value) => {
              inlineEditValue = value
            }
          "
        />
      </div>

      <div class="w-1/2">
        <h2 class="mt-8 mb-2">Flyout and Dialog</h2>
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

        <h2 class="mt-8 mb-2">Input Copy To Clipboard</h2>
        <div class="mb-6">
          <CommonInputCopyToClipboard
            value="some text to copy"
            label="A label"
          />
        </div>
      </div>

      <div class="w-1/2">
        <h2 class="text-lg">Form</h2>

        <Form
          id="playground-form"
          v-model="formValues"
          form-class="mb-2.5 space-y-2.5"
          :schema="formSchema"
          :initial-values="formInitialValues"
          @submit="console.debug($event)"
        >
          <template #after-fields>
            <div class="my-5 flex items-center justify-end gap-2">
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
        <pre
          class="flex flex-wrap gap-5 rounded-lg bg-blue-200 p-5 font-mono text-sm text-wrap text-gray-100 dark:bg-gray-700 dark:text-neutral-400"
          >{{ formValues }}</pre
        >
      </div>

      <h3>Tabs Groups</h3>
      <CommonTabGroup
        v-model="activeTab"
        class="mb-4"
        :tabs="[
          { label: 'Tab 1', key: 'tab-1' },
          { label: 'Tab 2', default: true, key: 'tab-2' },
          { label: 'Tab 3', key: 'tab-3' },
        ]"
      />

      <h3>Search Entities</h3>
      <CommonTabGroup
        v-model="activeTab"
        class="mb-4"
        size="medium"
        :tabs="[
          { label: 'Organization', count: 5, key: 'organization' },
          { label: 'Ticket', default: true, count: 5, key: 'ticket' },
          { label: 'User', key: 'user', count: 2 },
        ]"
      />

      <h3>Filter Selector</h3>
      <CommonTabGroup
        v-model="activeFilters"
        label="Roles"
        :tabs="[
          { label: 'Admin', key: 'admin' },
          { label: 'Agent', key: 'agent' },
          { label: 'Customer', key: 'customer' },
        ]"
        multiple
      />

      <h3>Split Button</h3>
      <div class="mb-3 flex justify-end gap-3">
        <SplitButton
          variant="submit"
          size="large"
          :items="splitButtonMenuItems"
          disabled
          >Disabled</SplitButton
        >
        <SplitButton
          variant="submit"
          size="large"
          addon-disabled
          @click="onSplitButtonClick"
          >Addon disabled</SplitButton
        >
        <SplitButton
          variant="submit"
          size="large"
          :items="splitButtonMenuItems"
          @click="onSplitButtonClick"
          >Update</SplitButton
        >
      </div>
    </div>
  </LayoutContent>
</template>
