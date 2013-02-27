#
# Author:: Marius Ducea (marius@promethost.com)
# Cookbook Name:: drupal
# Recipe:: default
#
# Copyright 2010, Promet Solutions
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

chef_gem "ruby-shadow"

include_recipe %w{apache2 apache2::mod_php5 apache2::mod_rewrite apache2::mod_expires}
include_recipe %w{php php::module_mysql php::module_gd}
include_recipe "postfix"
include_recipe "drupal::drush"

# Centos does not include the php-dom extension in it's minimal php install.
case node['platform_family']
when 'rhel', 'fedora'
  package 'php-dom' do
    action :install
  end
end

if node['drupal']['db']['host'] == "localhost"
  include_recipe "mysql::server"
else
  include_recipe "mysql::client"
end

user node['drupal']['system']['user'] do
  home node['drupal']['dir']
  shell "/bin/bash"
  password node['drupal']['system']['pass_hash']
end

directory node['drupal']['dir'] do
  owner node['drupal']['system']['user']
  group node['drupal']['system']['user']
  mode 00755
  recursive true
end

execute "download-drupal" do
  cwd  File.dirname(node['drupal']['dir'])
  user node['drupal']['system']['user']
  command "#{node['drupal']['drush']['dir']}/drush -y dl drupal-#{node['drupal']['version']} --destination=#{File.dirname(node['drupal']['dir'])} --drupal-project-rename=#{File.basename(node['drupal']['dir'])}"
  not_if "#{node['drupal']['drush']['dir']}/drush -r #{node['drupal']['dir']} status | grep #{node['drupal']['version']}"
  retries 3
end

web_app "drupal" do
  template "drupal.conf.erb"
  docroot node['drupal']['dir']
  server_name server_fqdn
  server_aliases node['fqdn']
end

include_recipe "drupal::cron"

execute "disable-default-site" do
   command "sudo a2dissite default"
   notifies :reload, "service[apache2]", :delayed
   only_if do File.exists? "#{node['apache']['dir']}/sites-enabled/default" end
end
