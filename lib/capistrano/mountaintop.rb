require 'capistrano'
require 'capistrano/campfire'
require 'capistrano/log_with_awesome'
# TODO need to handle loading a bit beter. these would load into the instance if it's defined
module Capistrano
  module Mountaintop
    def self.load_into(configuration)

      configuration.load do

        before 'deploy', 'mountaintop:campfire:starting'
        after 'deploy',  'mountaintop:campfire:finished'

        namespace :mountaintop do
          namespace :campfire do
            task :starting do
              announced_deployer = fetch(:deployer,  `git config user.name`.chomp)
              announced_stage = fetch(:stage, 'production')
              
              campfire_room.speak "#{announced_deployer} is deploying #{application}'s #{branch} to #{announced_stage}"
            end


            task :finished do
              campfire_room.paste fetch(:full_log)
            end
          end
        end
      end
    end
  end
end

if Capistrano::Configuration.instance
  Capistrano::Mountaintop.load_into(Capistrano::Configuration.instance)
end
  
