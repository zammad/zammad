// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { RouteRecordRaw } from 'vue-router'

export const isMainRoute = true

const route: RouteRecordRaw[] = [
  {
    path: '/guided-setup',
    name: 'GuidedSetup',
    component: () => import('./views/GuidedSetup.vue'),
    children: [
      {
        path: '',
        name: 'GuidedSetupStart',
        component: () => import('./views/GuidedSetupStart.vue'),
        meta: {
          title: __('Get Started'),
          requiresAuth: false,
          requiredPermission: null,
          hasOwnLandmarks: true,
          sidebar: false,
        },
      },
      {
        path: 'automated/',
        name: 'GuidedSetupAutomatedInfo',
        component: () =>
          import('./views/GuidedSetupAutomated/GuidedSetupAutomatedInfo.vue'),
        meta: {
          title: __('Automated Setup'),
          requiresAuth: false,
          requiredPermission: null,
          hasOwnLandmarks: true,
          sidebar: false,
        },
      },
      {
        path: 'automated/run/:token?',
        name: 'GuidedSetupAutomatedRun',
        props: true,
        component: () =>
          import('./views/GuidedSetupAutomated/GuidedSetupAutomatedRun.vue'),
        meta: {
          title: __('Automated Setup'),
          requiresAuth: false,
          requiredPermission: null,
          hasOwnLandmarks: true,
          sidebar: false,
        },
      },
      {
        path: 'manual',
        name: 'GuidedSetupManual',
        component: () =>
          import('./views/GuidedSetupManual/GuidedSetupManual.vue'),
        children: [
          {
            path: 'admin',
            alias: '',
            name: 'GuidedSetupManualAdmin',
            component: () =>
              import('./views/GuidedSetupManual/GuidedSetupManualAdmin.vue'),
            meta: {
              title: __('Create Administrator Account'),
              requiresAuth: false,
              requiredPermission: null,
              hasOwnLandmarks: true,
              sidebar: false,
            },
          },
          {
            path: 'finish',
            alias: '',
            name: 'GuidedSetupManualFinish',
            component: () =>
              import('./views/GuidedSetupManual/GuidedSetupManualFinish.vue'),
            meta: {
              title: __('Setup Finished'),
              requiresAuth: true,
              requiredPermission: 'admin.wizard',
              hasOwnLandmarks: true,
              sidebar: false,
            },
          },
          {
            path: 'system-information',
            name: 'GuidedSetupManualSystemInformation',
            component: () =>
              import(
                './views/GuidedSetupManual/GuidedSetupManualSystemInformation.vue'
              ),
            meta: {
              title: __('System Information'),
              requiresAuth: true,
              requiredPermission: 'admin.wizard',
              hasOwnLandmarks: true,
              sidebar: false,
            },
          },
          {
            path: 'email-notification',
            name: 'GuidedSetupManualEmailNotification',
            component: () =>
              import(
                './views/GuidedSetupManual/GuidedSetupManualEmailNotification.vue'
              ),
            meta: {
              title: __('Email Notification'),
              requiresAuth: true,
              requiredPermission: 'admin.wizard',
              hasOwnLandmarks: true,
              sidebar: false,
            },
          },
          {
            path: 'channels',
            name: 'GuidedSetupManualChannels',
            component: () =>
              import('./views/GuidedSetupManual/GuidedSetupManualChannels.vue'),
            meta: {
              title: __('Connect Channels'),
              requiresAuth: true,
              requiredPermission: 'admin.wizard',
              hasOwnLandmarks: true,
              sidebar: false,
            },
          },
          {
            path: 'channels/email',
            name: 'GuidedSetupManualChannelEmail',
            component: () =>
              import(
                './views/GuidedSetupManual/GuidedSetupManualChannelEmail.vue'
              ),
            meta: {
              title: __('Email Account'),
              requiresAuth: true,
              requiredPermission: 'admin.wizard',
              hasOwnLandmarks: true,
              sidebar: false,
            },
          },
          {
            path: 'channels/email-pre-configured',
            name: 'GuidedSetupManualChannelEmailPreConfigured',
            component: () =>
              import(
                './views/GuidedSetupManual/GuidedSetupManualChannelEmailPreConfigured.vue'
              ),
            meta: {
              title: __('Connect Channels'),
              requiresAuth: true,
              requiredPermission: 'admin.wizard',
              hasOwnLandmarks: true,
              sidebar: false,
            },
          },
          {
            path: 'invite',
            name: 'GuidedSetupManualInviteColleagues',
            component: () =>
              import(
                './views/GuidedSetupManual/GuidedSetupManualInviteColleagues.vue'
              ),
            meta: {
              title: __('Invite Colleagues'),
              requiresAuth: true,
              requiredPermission: 'admin.wizard',
              hasOwnLandmarks: true,
              sidebar: false,
            },
          },
        ],
      },
    ],
  },
]

export default route
