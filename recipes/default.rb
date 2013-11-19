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

if node['drupal']['db']['driver'] == 'mysql'
  if node['drupal']['site']['host'] == "localhost" or node['drupal']['site']['host'] == "127.0.0.1"
    include_recipe "mysql::server"
  else
    include_recipe "mysql::client"
  end

  execute "create #{node['drupal']['db']['database']} database" do
    command "/usr/bin/mysqladmin -h #{node['drupal']['db']['host']} -u root -p#{node['mysql']['server_root_password']} create #{node['drupal']['db']['database']}"
    not_if "mysql -h #{node['drupal']['db']['host']} -u root -p#{node['mysql']['server_root_password']} --silent --skip-column-names --execute=\"show databases like '#{node['drupal']['db']['database']}'\" | grep #{node['drupal']['db']['database']}"
    notifies :create, "template[/etc/mysql/drupal-grants.sql]", :immediately
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
        :host     => node['drupal']['db']['host']
    )
    notifies :run, "execute[mysql-install-drupal-privileges]", :immediately
    action :create
  end

  execute "mysql-install-drupal-privileges" do
    command "/usr/bin/mysql -h #{node['drupal']['db']['host']} -u root -p#{node['mysql']['server_root_password']} < /etc/mysql/drupal-grants.sql"
    action :nothing
  end

else
  log "drupal-database-driver" do
    message "You database driver (#{node['drupal']['db']['driver']}) is not supported here!"
    level :error
  end
end

#require '/opt/chef/embedded/lib/ruby/gems/1.9.1/gems/awesome_print-1.1.0/lib/awesome_print.rb'
#ap node['drupal']

directory "#{node['drupal']['dir']}" do
  mode "0755"
  action :create
  recursive true
  notifies :run, "bash[set-path-permissions]", :immediately
end

bash "set-path-permissions" do
  code "dir=#{node['drupal']['dir']} ; while test \"/\" != \"$dir\" ; do echo chmod 755 $dir ; dir=$(dirname $dir) ; done"
  action :nothing
  notifies :run, "execute[unpack-drupal]", :immediately
end

execute "unpack-drupal" do
  cwd  File.dirname(node['drupal']['dir'])
  command "#{node['drupal']['drush']['dir']}/drush -y dl drupal-#{node['drupal']['version']} --destination=#{File.dirname(node['drupal']['dir'])} --drupal-project-rename=#{File.basename(node['drupal']['dir'])}"
  not_if "#{node['drupal']['drush']['dir']}/drush -r #{node['drupal']['dir']} status | grep #{node['drupal']['version']}"
  action :run
  notifies :create, "directory[#{node['drupal']['dir']}/sites/default/files]", :immediately
  notifies :run, "execute[#{node['drupal']['dir']}-permissions]", :immediately
end

if node['drupal']['sites']['default']['settings']['action'].is_a?(String)
  node.set[:drupal][:sites][:default][:settings][:action] = node['drupal']['sites']['default']['settings']['action'].to_sym
end

#if node[:drupal][:version].match(%r/^6/)
settings_php = "#{node['drupal']['dir']}/sites/default/settings.php"
#else
#  settings_php = "/tmp/settings.php"
#end

do_action = :create_if_missing
if node[:drupal][:site_install][:force] == 'yes'
	do_action = :create
end
# Override the settings file for local configuration.
if node['drupal']['sites']['default']['settings']['template']
  template settings_php do
    cookbook node['drupal']['sites']['default']['settings']['cookbook']
    source node['drupal']['sites']['default']['settings']['template']
    mode 0644
    owner node['drupal']['owner']
    group node['drupal']['group']
    action node['drupal']['sites']['default']['settings']['action']
    notifies :run, "execute[cleanup-settings-php]", :immediately
    action do_action
  end
else
  file settings_php do
    # [2013-10-16 Christo] We assume that if it is NOT Drupal 6 then it is 7 or higher ...
    mode 0644
    owner node['drupal']['owner']
    group node['drupal']['group']
    content node[:drupal][:version].match(%r/^6/) ?
                %(<?php

    $db_url = array(
        'default' => "#{node[:drupal][:db][:driver]}://#{node[:drupal][:db][:user]}:#{node[:drupal][:db][:password]}@#{node[:drupal][:db][:host]}:#{node[:drupal][:db][:port]}/#{node[:drupal][:db][:database]}",
    );
    $db_prefix = array(
        'default'   => '',
    );
)
            :
                %(<?php

  $databases = array (
    'default' =>
    array (
      'default' =>
      array (
        'database' => '#{node['drupal']['db']['database']}',
        'username' => '#{node['drupal']['db']['user']}',
        'password' => '#{node['drupal']['db']['password']}',
        'host'     => '#{node['drupal']['db']['host']}',
        'port'     => '#{node['drupal']['db']['port']}',
        'driver'   => '#{node['drupal']['db']['diver']}',
        'prefix'   => '#{node['drupal']['db']['prefix']}',
      ),
    ),
  );

)
    action node['drupal']['sites']['default']['settings']['action']
    only_if "test -d #{node['drupal']['dir']}"
    notifies :run, "execute[cleanup-settings-php]", :immediately
  end
end

execute "cleanup-settings-php" do
  command %(sed -i '/^#/d; /\\/\\*/,/*\\//d; /^\\/\\//d; /^$/d; ' #{settings_php})
  not_if %(test -z "`egrep -e '^(/\\\\*|\\\\*/|//|#)' #{settings_php}`")
  only_if { File.exists?(settings_php) }
  notifies :run, "execute[configure-drupal]", :immediately
end

if (node[:drupal][:db][:host] != '127.0.0.1') and (node[:drupal][:db][:host_safety_override] != 'yes')
  log 'cowardly-refuse-non-localhost-db' do
    message "I cowardly refuse to (re)install your Drupal site when the database is not hosted locally."
    level :error
  end
end

# [2013-10-08 Christo] This will fail in a weird way if the credentials in the settings.php don't work!
if node[:drupal][:version].match(%r/^6/)
  si_dbu = "--db-url='#{node[:drupal][:db][:driver]}://#{node[:drupal][:db][:user]}:#{node[:drupal][:db][:password]}@#{node[:drupal][:db][:host]}:#{node[:drupal][:db][:port]}/#{node[:drupal][:db][:database]}'"
else
  si_dbu = ''
end

si_cmd = <<-EOSIC
#{node['drupal']['drush']['dir']}/drush
site-install
-r #{node['drupal']['dir']}
--account-name=#{node['drupal']['site']['admin']}
--account-pass=#{node['drupal']['site']['pass']}
--site-name="#{node['drupal']['site']['name']}"
#{si_dbu}
-y
EOSIC
# Compress whitespace and make a single line
si_cmd.gsub!(%r/[\r\n]+/,' ').gsub!(%r/\s+/,' ')

cfg_drupal = execute "configure-drupal" do
  cwd  File.dirname(node['drupal']['dir'])
  command si_cmd
  only_if "test -d #{node['drupal']['dir']}"
  not_if %(mysql -h #{node['drupal']['db']['host']} -u root -p#{node['mysql']['server_root_password']} --silent --skip-column-names --execute="select * from variable where name = 'drupal_http_request_fails';" #{node['drupal']['db']['database']})
  # [2013-10-15 Christo] Please note that for mysql 127.0.0.1 and localhost are not EXACTLY the same thing ... We use the IP address with careful intent.
  only_if { (node[:drupal][:db][:host] == '127.0.0.1') or (node[:drupal][:db][:host_safety_override] == 'yes') }
  action :nothing
  notifies :restart, "service[apache2]", :immediately
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
# user/group owns everything
/bin/chown -R #{node['drupal']['owner']}:#{node['drupal']['group']} #{node['drupal']['dir']};
# Directories can be traversed
/bin/find #{node['drupal']['dir']} -type d -exec /bin/chmod u=rwx,g=rx,o= {} \\; ;
# And files are writeable only by owner and read-only for group
/bin/find #{node['drupal']['dir']} -type f -exec /bin/chmod u=rw,g=r,o= {} \\; ;
# sites directories writeable+negotiable by owner and group
/bin/find #{node['drupal']['dir']}/sites -type d -name files -exec /bin/chmod ug=rwx,o= {} \\; ;
# sites/*/files directories negotiable and readable by all and writeable by owner/group
for x in #{node['drupal']['dir']}/sites/*/files; do
	/bin/find ${x} -type d -exec /bin/chmod ug=rwx,o= '{}' \\; ;
	/bin/find ${x} -type f -exec /bin/chmod ug=rw,o= '{}' \\; ;
done ;
"
  notifies :restart, "service[apache2]", :delayed
end

if node.has_key?("ec2")
  server_fqdn = node['ec2']['public_hostname']
else
  server_fqdn = node['fqdn']
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

unless File.exist?(settings_php)
  Chef::Log.error "#{settings_php} is not available!"
end

modules = {}
if node['drupal']['modules']
  node['drupal']['modules'].each do |dm|
    m = if dm.is_a?Array
          dm
        else
          [dm]
        end
    modules[m] = drupal_module m.first do
      version m.last
      dir node['drupal']['dir']
      action :nothing
      subscribes :install, "execute[configure-drupal]", :immediately
    end
  end
end
