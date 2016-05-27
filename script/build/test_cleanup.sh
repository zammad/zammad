#!/bin/bash

rake db:drop RAILS_ENV=test
rake db:drop RAILS_ENV=production