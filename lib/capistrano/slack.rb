require 'capistrano'
require 'capistrano/log_with_awesome'
require 'json'
require 'net/http'
# TODO need to handle loading a bit beter. these would load into the instance if it's defined
module Capistrano
  module Slack
    def self.extended(configuration)
      configuration.load do

        before 'deploy', 'slack:starting'
        before 'deploy:migrations', 'slack:starting'
        after 'deploy',  'slack:finished'
        before "monit:config", 'slack:monit'

        set :deployer do
          ENV['GIT_AUTHOR_NAME'] || `git config user.name`.chomp
        end


        namespace :slack do
          task :starting do
            slack_token = fetch(:slack_token)
            slack_room = fetch(:slack_room)
            slack_emoji = fetch(:slack_emoji) || ":ghost:"
            slack_username = fetch(:slack_username) || "deploybot"
            slack_subdomain = fetch(:slack_subdomain)
            return if slack_token.nil?
            announced_deployer = fetch(:deployer)
            announced_stage = fetch(:stage, 'production')

            announcement = if fetch(:branch, nil)
                             "#{announced_deployer} is deploying #{branch} to #{announced_stage}"
                           else
                             "#{announced_deployer} is deploying to #{announced_stage}"
                           end
            

            # Parse the API url and create an SSL connection
            uri = URI.parse("https://#{slack_subdomain}.slack.com/services/hooks/incoming-webhook?token=#{slack_token}")
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE

            # Create the post request and setup the form data
            request = Net::HTTP::Post.new(uri.request_uri)
            request.set_form_data(:payload => {'channel' => slack_room, 'username' => slack_username, 'text' => announcement, "icon_emoji" => slack_emoji}.to_json)

            # Make the actual request to the API
            response = http.request(request)

            set(:start_time, Time.now)
          end


          task :finished do
            slack_token = fetch(:slack_token)
            slack_room = fetch(:slack_room)
            slack_emoji = fetch(:slack_emoji) || ":ghost:"
            slack_username = fetch(:slack_username) || "deploybot"
            slack_subdomain = fetch(:slack_subdomain)
            announced_stage = fetch(:stage, 'production')
            return if slack_token.nil?
            announced_deployer = fetch(:deployer)
            end_time = Time.now
            begin
              start_time = fetch(:start_time)
              elapsed = end_time.to_i - start_time.to_i
            rescue
              elapsed = "Unknown"
            end

          
            msg = "#{announced_deployer} deployed successfully in #{elapsed} seconds to #{announced_stage}."
            
            # Parse the URI and handle the https connection
            uri = URI.parse("https://#{slack_subdomain}.slack.com/services/hooks/incoming-webhook?token=#{slack_token}")
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE

            # Create the post request and setup the form data
            request = Net::HTTP::Post.new(uri.request_uri)
            request.set_form_data(:payload => {'channel' => slack_room, 'username' => slack_username, 'text' => msg, "icon_emoji" => slack_emoji}.to_json)
            
            # Make the actual request to the API
            response = http.request(request)
          end

          task :monit do
            slack_token = fetch(:slack_token)
            slack_room = fetch(:slack_room)
            slack_emoji = fetch(:slack_emoji) || ":ghost:"
            slack_username = fetch(:slack_username) || "deploybot"
            slack_subdomain = fetch(:slack_subdomain)
            return if slack_token.nil?
            announced_deployer = fetch(:deployer)
          
            msg = "#{announced_deployer} is reconfiguring monit on #{stage} with the #{branch} branch."
            
            # Parse the URI and handle the https connection
            uri = URI.parse("https://#{slack_subdomain}.slack.com/services/hooks/incoming-webhook?token=#{slack_token}")
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE

            # Create the post request and setup the form data
            request = Net::HTTP::Post.new(uri.request_uri)
            request.set_form_data(:payload => {'channel' => slack_room, 'username' => slack_username, 'text' => msg, "icon_emoji" => slack_emoji}.to_json)
            
            # Make the actual request to the API
            response = http.request(request)
          end
        end
      end
    end
  end
end

if Capistrano::Configuration.instance
  Capistrano::Configuration.instance.extend(Capistrano::Slack)
end
  
