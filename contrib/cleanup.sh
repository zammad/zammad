#!/bin/bash

set -ex

rm app/assets/javascripts/app/controllers/layout_ref.coffee
rm -rf app/assets/javascripts/app/views/layout_ref/
rm app/assets/javascripts/app/controllers/karma.coffee
rm app/assets/javascripts/app/controllers/report.coffee
rm app/assets/javascripts/app/controllers/report_profile.coffee
rm app/assets/javascripts/app/controllers/_integration/check_mk.coffee
rm app/assets/javascripts/app/controllers/_integration/idoit.coffee
