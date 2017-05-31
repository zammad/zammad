# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
require 'ldap'
require 'ldap/user'
require 'ldap/group'

class Integration::LdapController < ApplicationController
  prepend_before_action { authentication_check(permission: 'admin.integration.ldap') }

  def discover
    ldap = ::Ldap.new(params)

    render json: {
      result:     'ok',
      attributes: ldap.preferences,
    }
  rescue => e
    # workaround for issue #1114
    if e.message.end_with?(', 48, Inappropriate Authentication')
      result = {
        result:     'ok',
        attributes: {},
      }
    else
      logger.error e
      result = {
        result:  'failed',
        message: e.message,
      }
    end

    render json: result
  end

  def bind
    # create single instance so
    # User and Group don't have to
    # open new connections
    ldap  = ::Ldap.new(params)
    user  = ::Ldap::User.new(params, ldap: ldap)
    group = ::Ldap::Group.new(params, ldap: ldap)

    render json: {
      result: 'ok',

      # the order of these calls is relevant!
      user_filter:     user.filter,
      user_attributes: user.attributes,
      user_uid:        user.uid_attribute,

      # the order of these calls is relevant!
      group_filter: group.filter,
      groups:       group.list,
      group_uid:    group.uid_attribute,
    }
  rescue => e
    logger.error e

    render json: {
      result:  'failed',
      message: e.message,
    }
  end

  def job_try_index
    job_index(
      dry_run:       true,
      take_finished: params[:finished] == 'true'
    )
  end

  def job_try_create
    ImportJob.dry_run(name: 'Import::Ldap', payload: params)
    render json: {
      result: 'ok',
    }
  end

  def job_start_index
    job_index(dry_run: false)
  end

  def job_start_create
    backend = 'Import::Ldap'
    if !ImportJob.exists?(name: backend, finished_at: nil)
      job = ImportJob.create(name: backend, payload: Setting.get('ldap_config'))
      job.delay.start
    end
    render json: {
      result: 'ok',
    }
  end

  private

  def job_index(dry_run:, take_finished: true)
    job = ImportJob.find_by(name: 'Import::Ldap', dry_run: dry_run, finished_at: nil)
    if !job && take_finished
      job = ImportJob.where(name: 'Import::Ldap', dry_run: dry_run).order(created_at: :desc).limit(1).first
    end

    if job
      model_show_render_item(job)
    else
      render json: {}
    end
  end
end
