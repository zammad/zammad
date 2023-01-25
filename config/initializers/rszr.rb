# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

#
# https://github.com/zammad/zammad/issues/4347
# This file will be removed along with lib/core_ext/rszr.rb
# When all supported Linux distributions update to >= 1.9 imlib2

Rszr.autorotate = Rszr.needs_autorotate_fix?
