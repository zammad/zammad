// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import log from '@common/utils/log'
import * as ActionCable from '@rails/actioncable'

ActionCable.adapters.logger = log as unknown as Console
ActionCable.logger.enabled = true

export default ActionCable.createConsumer()
