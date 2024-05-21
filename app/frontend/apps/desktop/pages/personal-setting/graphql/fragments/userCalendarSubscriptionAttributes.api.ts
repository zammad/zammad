import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const UserCalendarSubscriptionAttributesFragmentDoc = gql`
    fragment userCalendarSubscriptionAttributes on UserPersonalSettingsCalendarSubscriptionsConfig {
  combinedUrl
  globalOptions {
    alarm
  }
  newOpen {
    url
    options {
      own
      notAssigned
    }
  }
  pending {
    url
    options {
      own
      notAssigned
    }
  }
  escalation {
    url
    options {
      own
      notAssigned
    }
  }
}
    `;