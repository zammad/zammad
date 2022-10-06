# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class ImportOtrsController < ApplicationController

  def url_check
    return if setup_done_response

    # validate
    if !params[:url] || params[:url] !~ %r{^(http|https)://.+?$}
      render json: {
        result:  'invalid',
        message: __('The provided URL is invalid.'),
      }
      return
    end

    # connection test
    translation_map = {
      'authentication failed'                                     => __('Authentication failed.'),
      'getaddrinfo: nodename nor servname provided, or not known' => __('The hostname could not be found.'),
      'No route to host'                                          => __('There is no route to this host.'),
      'Connection refused'                                        => __('The connection was refused.'),
    }

    response = UserAgent.request(params[:url])
    if !response.success? && response.code.to_s !~ %r{^40.$}
      message_human = ''
      translation_map.each do |key, message|
        if response.error.to_s.match?(%r{#{Regexp.escape(key)}}i)
          message_human = message
        end
      end
      render json: {
        result:        'invalid',
        message_human: message_human,
        message:       response.error.to_s,
      }
      return
    end

    result = {}
    if response.body.include?('zammad migrator')

      migrator_response = JSON.parse(response.body)

      if migrator_response['Success'] == 1

        # set url and key for import endpoint
        url = migrator_response['URL']
        key = migrator_response['Key']

        # get first part url, used for import_otrs_endpoint
        if !url || !key
          url_parts = params[:url].split(';')
          if !url_parts[1] # in case of & instead of ;
            url_parts = params[:url].split('&')
          end
          key_parts = url_parts[1].split('=')

          if !key_parts[1]
            render json: {
              result:        'invalid',
              message_human: __('Import API key could not be extracted from URL.')
            }
            return
          end
          if !url
            url = url_parts[0]
          end
          if !key
            key = key_parts[1]
          end
        end

        Setting.set('import_backend', 'otrs')
        Setting.set('import_otrs_endpoint', url)
        Setting.set('import_otrs_endpoint_key', key)

        result = {
          result: 'ok',
          url:    params[:url],
        }
      else
        result = {
          result:        'invalid',
          message_human: migrator_response['Error']
        }
      end
    elsif response.body.match?(%r{(otrs\sag|otrs\.com|otrs\.org)}i)
      result = {
        result:        'invalid',
        message_human: __('Host found, but no OTRS migrator is installed!')
      }
    else
      result = {
        result:        'invalid',
        message_human: __('Host found, but it seems to be no OTRS installation!'),
      }
    end

    render json: result
  end

  def import_start
    return if setup_done_response

    Setting.set('import_mode', true)
    welcome = Import::OTRS.connection_test
    if !welcome
      render json: {
        message: __('Migrator can\'t read OTRS output!'),
        result:  'invalid',
      }
      return
    end

    # start migration
    AsyncOtrsImportJob.perform_later

    render json: {
      result: 'ok',
    }
  end

  def import_check
    Import::OTRS::Requester.list
    issues = []

    # check count of dynamic fields
    dynamic_field_count = 0
    dynamic_fields = Import::OTRS::Requester.load('DynamicField')
    dynamic_fields.each do |dynamic_field|
      next if dynamic_field['ValidID'].to_i != 1

      dynamic_field_count += 1
    end
    if dynamic_field_count > 20
      issues.push 'otrsDynamicFields'
    end

    # check if process exsists
    sys_configs = Import::OTRS::Requester.load('SysConfig')
    sys_configs.each do |sys_config|
      next if sys_config['Key'] != 'Process'

      issues.push 'otrsProcesses'
    end

    result = 'ok'
    if issues.present?
      result = 'failed'
    end
    render json: {
      result: result,
      issues: issues,
    }
  end

  def import_status
    result = Import::OTRS.status_bg
    if result[:result] == 'import_done'
      Setting.reload
    end
    render json: result
  end

  private

  def setup_done
    count = User.all.count()
    done = true
    if count <= 2
      done = false
    end
    done
  end

  def setup_done_response
    if !setup_done
      return false
    end

    render json: {
      setup_done: true,
    }
    true
  end

end
