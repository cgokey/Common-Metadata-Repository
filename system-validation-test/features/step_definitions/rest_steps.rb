# frozen_string_literal: true

require 'httparty'
require 'json'
require 'jsonpath'

cmr_root ||= ENV['CMR_ROOT']

# Module to help build CMR queries
module CmrRestfulHelper
  # Appends new values to the query map,
  # if already present the entry will be converted to an array
  def append_query(query, key, value)
    query ||= {}

    # HTTParty supports array of parameters but automatically adds square braces
    key = key[0..-3] if key.match?(/\[\]$/)

    if query.key?(key)
      query[key] = [query[key]] unless query[key].is_a?(Array)
      query[key] << value
    else
      query[key] = value
    end

    query
  end

  # Appends new values to the query map,
  # if already present the entry will be overwritten
  def update_query(query, key, value)
    query ||= {}

    # HTTParty supports array of parameters but automatically adds square braces
    key = key[0..-3] if key.match?(/\[\]$/)
    query[key] = value

    query
  end

  # Send the query
  def submit_query(method, url, options)
    resource_uri = URI(url)

    case method.upcase
    when 'GET'
      response = HTTParty.get(resource_uri, options)
    else
      raise "#{method} is not supported yet"
    end

    response
  end
end
World CmrRestfulHelper

Given('I use/set the authorization token from/with/using environment variable/value {string}') do |variable|
  token = ENV[variable]

  raise "No Token string found in environment using #{variable}" if token.to_s.empty?

  token = if token.start_with?('EDL')
            "Bearer #{token}"
          else
            token
          end

  @headers ||= {}
  @headers = @headers.merge({ 'Authorization' => token })
end

Given('I use/set the authorization token to {string}') do |token|
  @headers ||= {}
  @headers = @headers.merge({ 'Authorization' => token }) unless @token.to_s.empty?
end

Given('I am not logged in') do
  @token = nil

  @headers ||= {}
  @headers.delete('Authorization')
end

Given(/^I am (searching|querying|looking) for (an? )?"([\w\d\-_ ]+)"$/) do |_, _, concept_type|
  @resource_url = case concept_type.downcase
                  when /^acls?$/
                    "#{cmr_root}/access-control/acls"
                  when /^groups?$/
                    "#{cmr_root}/access-control/groups"
                  when /^permissions?$/
                    "#{cmr_root}/access-control/permissions"
                  when /^s3-buckets?$/
                    "#{cmr_root}/access-control/s3-buckets"
                  when /^(concept|collection|granule|service|tool|variable)s?$/
                    "#{cmr_root}/search/#{concept_type}"
                  else
                    raise "#{concept_type} searching is not available in CMR"
                  end
end

Given('I clear/reset/remove/delete the extension') do
  @url_extension = nil
end

Given('I use/add extension {string}') do |extension|
  @url_extension = extension
end

Given(/^I (want|ask for|request) (an? )?"(\w+)"( (response|returned))?$/) do |_, _, format, _|
  @url_extension = case format.downcase
                   when 'json', 'xml', 'dif', 'dif10', 'echo10', 'atom', 'native', 'iso', 'iso19115'
                     ".#{format}"
                   when 'umm_json', 'umm'
                     # modern umm
                     '.umm_json'
                   when 'umm-json', 'legacy-umm-json', 'legacy-umm'
                     # legacy umm
                     '.umm-json'
                   else
                     raise "#{format} does not have a mapping to an extension yet"
                   end
end

Given(/^I (set|add) header "([\w\d\-_+]+)=(.*)"$/) do |_, header, value|
  @headers ||= {}
  @headers[header] = value
end

Given(/^I (set|add) header "([\w\d\-_+]+)" using environment ((variable|value) )?"(.*)"$/) do |_, header, _, env_key|
  pending("Need to set #{env_key} in environment or cucumber profile") unless ENV[env_key]

  @headers ||= {}
  @headers[header] = ENV[env_key]
end

Given(/^I (set|add) header "([\w\d\-_+]+)" using stored value "(.*)"$/) do |_, header, stored_value_key|
  pending("Need to save a value for  #{store_value_key} first") unless @stashes[stored_value_key]

  @headers ||= {}
  @headers[header] = @stashes[stored_value_key]
end

Given('I reset/clear/delete/remove the query') do
  @query = nil
end

Given(/^I (set|add) (a )?(search|query) (param(eter)?|term) "([\w\d\-_+\[\]]+)=(.*)"$/) do |op, _, _, _, key, value|
  @query = if op == 'add'
             append_query(@query, key, value)
           else
             update_query(@query, key, value)
           end
end

Given(/^I (set|add) (a )?(search|query) (param(eter)?|term) "([\w\d\-_+\[\]]+)" (of|to) "(.*)"$/) do |op, _, _, _, key, _, value|
  @query = if op == 'add'
             append_query(@query, key, value)
           else
             update_query(@query, key, value)
           end
end

Given(/^I (set|add) (a )?(search|query) (param(eter)?|term) "([\w\d\-_+\[\]]+)" using saved value "(.*)"$/) do |op, _, _, _, key, saved_value_key|
  raise "No value for #{env_key} in stored values" unless @stashes[saved_value_key]

  @query = if op == 'add'
             append_query(@query, key, @stashes[saved_value_key])
           else
             update_query(@query, key, @stashes[saved_value_key])
           end
end

Given(/^I (set|add) (a )?(search|query) (param(eter)?|term) "([\w\d\-_+\[\]]+)" using environment (value|variable) "(.*)"$/) do |op, _, _, _, key, _, env_key|
  pending("Need to set #{env_key} in environment or cucumber profile") unless ENV[env_key]

  @query = if op == 'add'
             append_query(@query, key, ENV[env_key])
           else
             update_query(@query, key, ENV[env_key])
           end
end

When(/^I (submit|send) (a|another) "(\w+)" request to "(.*)"$/) do |_, _, method, url|
  url = "#{cmr_root}#{url}#{@url_extension}"
  options = { query: @query,
              headers: @headers }
  @response = submit_query(method, url, options)
end

When(/^I (submit|send) (a|another) "(\w+)" request$/) do |_, _, method|
  url = "#{@resource_url}#{@url_extension}"
  options = { query: @query,
              headers: @headers }

  @response = submit_query(method, url, options)
end

Then(/^the response (status( code)?) is (\d+)$/) do |_, status_code|
  expect(@response.code).to eq(status_code)
end

Then('the response Content-Type is {string}') do |content_type|
  actual_type = @response.headers['Content-Type'].split(';')
  expect(actual_type[0]).to eq(content_type)
end

When(/^I save the response (as|into) "(\w[\w\d\-_ ]+)"$/) do |_, name|
  @stashes ||= {}
  @stashes = @stashes.merge({ name => @response })
end

When(/^I save the response body (as|into) "(\w[\w\d\-_ ]+)"$/) do |_, name|
  @stashes ||= {}
  @stashes = @stashes.merge({ name => @response.body })
end

When(/^I save the response headers (as|into) "(\w[\w\d\-_ ]+)"$/) do |_, name|
  @stashes ||= {}
  @stashes = @stashes.merge({ name => @response.headers })
end

When(/^I save the response header "(\w+)" (as|into) "(\w[\w\d\-_ ]+)"$/) do |header, _, name|
  @stashes ||= {}
  @stashes = @stashes.merge({ name => @response.headers[header] })
end
