#!/bin/bash

bundle install
rake db:create
rake db:migrate
rake db:seed

