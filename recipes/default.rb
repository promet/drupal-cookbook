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

if node['drupal']['site']['host'] == "localhost" or node['drupal']['site']['host'] == "127.0.0.1"
  include_recipe "mysql::server"
else
  include_recipe "mysql::client"
end

execute "create #{node['drupal']['db']['database']} database" do
  command "/usr/bin/mysqladmin -h #{node['drupal']['db']['host']} -u root -p#{node['mysql']['server_root_password']} create #{node['drupal']['db']['database']}"
  not_if "mysql -h #{node['drupal']['db']['host']} -u root -p#{node['mysql']['server_root_password']} --silent --skip-column-names --execute=\"show databases like '#{node['drupal']['db']['database']}'\" | grep #{node['drupal']['db']['database']}"
end

execute "mysql-install-drupal-privileges" do
  command "/usr/bin/mysql -h #{node['drupal']['db']['host']} -u root -p#{node['mysql']['server_root_password']} < /etc/mysql/drupal-grants.sql"
  action :nothing
end

template "/etc/mysql/drupal-grants.sql" do
  path "/etc/mysql/drupal-grants.sql"
  source "grants.sql.erb"
  owner "root"
  group "root"
  mode "0600"
  variables(
    :user     => node['drupal']['db']['user'],
    :password => node['drupal']['db']['password'],
    :database => node['drupal']['db']['database'],
    :host => node['drupal']['site']['host']
  )
  notifies :run, "execute[mysql-install-drupal-privileges]", :immediately
end

#require '/opt/chef/embedded/lib/ruby/gems/1.9.1/gems/awesome_print-1.1.0/lib/awesome_print.rb'
#ap node['drupal']

directory "#{node['drupal']['dir']}" do
  mode "0755"
  action :create
  recursive true
  notifies :run, "execute[unpack-drupal]", :immediately
end

execute "unpack-drupal" do
  cwd  File.dirname(node['drupal']['dir'])
  command "#{node['drupal']['drush']['dir']}/drush -y dl drupal-#{node['drupal']['version']} --destination=#{File.dirname(node['drupal']['dir'])} --drupal-project-rename=#{File.basename(node['drupal']['dir'])}"
  not_if "#{node['drupal']['drush']['dir']}/drush -r #{node['drupal']['dir']} status | grep #{node['drupal']['version']}"
  #only_if "mysql -h #{node['drupal']['db']['host']} -u root -p#{node['mysql']['server_root_password']} --silent --skip-column-names --execute=\"show databases like '#{node['drupal']['db']['database']}'\" | grep #{node['drupal']['db']['database']}"
  action :run
  notifies :create, "directory[#{node['drupal']['dir']}/sites/default/files]", :immediately
  notifies :create, "file[#{node['drupal']['dir']}/sites/default/settings.php]", :immediately
  notifies :run, "execute[#{node['drupal']['dir']}-permissions]", :immediately
end

# Override the settings file for local configuration.
if node['drupal']['sites']['default']['settings']['template']
  file "#{node['drupal']['dir']}/sites/default/settings.php" do
    content "<?php
# template[#{node['drupal']['dir']}/sites/default/settings.php]
"
    action :nothing
    notifies :create, "template[#{node['drupal']['dir']}/sites/default/settings.php]", :immediately
  end
  template "#{node['drupal']['dir']}/sites/default/settings.php" do
    cookbook node['drupal']['sites']['default']['settings']['cookbook']
    source node['drupal']['sites']['default']['settings']['template']
    mode 0644
    owner node['drupal']['owner']
    group node['drupal']['group']
    action :nothing
    notifies :run, "execute[configure-drupal]", :immediately
  end
else
  file "#{node['drupal']['dir']}/sites/default/settings.php" do
    content "<?php

  $databases = array (
    'default' =>
    array (
      'default' =>
      array (
        'database' => '#{node['drupal']['db']['database']}',
        'username' => '#{node['drupal']['db']['user']}',
        'password' => '#{node['drupal']['db']['password']}',
        'host'     => '#{node['drupal']['db']['host']}',
        'port' => '',
        'driver' => 'mysql',
        'prefix' => '',
      ),
    ),
  );

  "
    action :nothing
    only_if "test -d #{node['drupal']['dir']}"
    notifies :run, "execute[configure-drupal]", :immediately
  end
end

# Verify the existence of the #{node['drupal']['dir']}/sites/default folder
#if File.directory?("#{node['drupal']['dir']}/sites/default")
#else
#  Chef::Log.fatal("#{node['drupal']['dir']}/sites/default is missing!")
#end

cfg_drupal = execute "configure-drupal" do
  cwd  File.dirname(node['drupal']['dir'])
  command "#{node['drupal']['drush']['dir']}/drush -y site-install -r #{node['drupal']['dir']} --account-name=#{node['drupal']['site']['admin']} --account-pass=#{node['drupal']['site']['pass']} --site-name=\"#{node['drupal']['site']['name']}\"  "
  not_if "#{node['drupal']['drush']['dir']}/drush -r #{node['drupal']['dir']} status | grep #{node['drupal']['version']}"
  only_if "test -d #{node['drupal']['dir']}"
  action :nothing
  notifies :restart, "service[apache2]", :delayed
end

hostsfile_entry "#{node[:ipaddress]}" do
  hostname  node['drupal']['server_name']
end

directory "#{node['drupal']['dir']}/sites/default/files" do
  mode "0755"
  owner node['drupal']['owner']
  group node['drupal']['group']
  action :nothing
  recursive false
end

# Apache has write access to everything
#  execute "#{node['drupal']['dir']}-permissions" do
#    action :nothing
#    command "/bin/chown -R #{node['drupal']['owner']} #{node['drupal']['dir']};
#/bin/chgrp -R #{node['drupal']['group']} #{node['drupal']['dir']};
#/bin/find #{node['drupal']['dir']} -type d -exec chmod 0755 {} \\; ;
#/bin/find #{node['drupal']['dir']} -type f -exec chmod 0644 {} \\; ;
#/bin/chmod -R 777 #{node['drupal']['dir']}/sites/default/files ;
#"
#    notifies :restart, "service[apache2]", :delayed
#  end

# Apache only has write access to sites/default/files
execute "#{node['drupal']['dir']}-permissions" do
  action :nothing
  command "
/bin/chown -R root #{node['drupal']['dir']};
/bin/chgrp -R root #{node['drupal']['dir']};
/bin/find #{node['drupal']['dir']} -type d -exec chmod 0755 {} \\; ;
/bin/find #{node['drupal']['dir']} -type f -exec chmod 0644 {} \\; ;
/bin/chown -R #{node['drupal']['owner']} #{node['drupal']['dir']}/sites/default/files
/bin/chgrp -R #{node['drupal']['group']} #{node['drupal']['dir']}/sites/default/files
"
  notifies :restart, "service[apache2]", :delayed
end

if node.has_key?("ec2")
  server_fqdn = node['ec2']['public_hostname']
else
  server_fqdn = node['fqdn']
end

modules = {}
if node['drupal']['modules']
  node['drupal']['modules'].each do |m|
    if m.is_a?Array
      modules[m] = drupal_module m.first do
        version m.last
        dir node['drupal']['dir']
      end
    else
      modules[m] = drupal_module m do
        dir node['drupal']['dir']
      end
    end
  end

end

web_app_enable = (node['drupal']['web_app']['enable'] and !!node['drupal']['web_app']['enable'] == node['drupal']['web_app']['enable']) ? node['drupal']['web_app']['enable'] : node['drupal']['web_app']['enable'].downcase.match(%r/true|1|on|enable|yes/)
web_app "drupal" do
  template "drupal.conf.erb"
  docroot node['drupal']['dir']
  server_name node['drupal']['server_name']
  server_aliases node['fqdn']
  enable web_app_enable
end

include_recipe "drupal::cron"

execute "disable-default-site" do
   command "sudo a2dissite default"
   notifies :reload, "service[apache2]", :delayed
   only_if do File.exists? "#{node['apache']['dir']}/sites-enabled/default" end
end

if cfg_drupal.updated_by_last_action?
  unless File.exist?("#{node['drupal']['dir']}/sites/default/files/settings.php")
    Chef::Log.fatal "#{node['drupal']['dir']}/sites/default/files/settings.php is not available!"
  end
  modules.each{ |m,r|
    r.run_action(:run)
  }
end
