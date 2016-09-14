#!/bin/bash

set -ex

rm app/assets/javascripts/app/controllers/layout_ref.coffee
rm -rf app/assets/javascripts/app/views/layout_ref/
rm app/assets/javascripts/app/controllers/api.coffee
rm app/assets/javascripts/app/controllers/integrations.coffee
rm app/assets/javascripts/app/controllers/_integration/slack.coffee
rm app/assets/javascripts/app/controllers/_integration/sipgate_io.coffee
rm app/assets/javascripts/app/controllers/karma.coffee
rm app/assets/javascripts/app/controllers/_integration/nagios.coffee
rm app/assets/javascripts/app/controllers/_integration/icinga.coffee
rm app/assets/javascripts/app/controllers/_integration/clearbit.coffee
rm app/assets/javascripts/app/controllers/role.coffee
rm app/assets/javascripts/app/controllers/report.coffee
rm app/assets/javascripts/app/controllers/report_profile.coffee
