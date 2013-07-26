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

# @TODO remove after finalization
package 'git'
package 'tmux'
package 'htop'
package 'mc'

case node['drupal']['webserver']['type']
  when 'apache' then include_recipe %w{apache2 apache2::mod_php5 apache2::mod_rewrite apache2::mod_expires}
  when 'nginx' then include_recipe 'nginx'
end

include_recipe 'php'
include_recipe 'php::module_gd'
# Centos does not include the php-dom extension in it's minimal php install.
case node['platform_family']
when 'rhel', 'fedora'
  package 'php-dom' do
    action :install
  end
end

case node['drupal']['db']['type']
  when 'mysql' then include_recipe 'php::module_mysql'
  when 'postgresql' then include_recipe 'php::module_pgsql'
end

include_recipe "postfix"

include_recipe "drupal::drush"

if node['drupal']['site']['host'] == "localhost"
  case node['drupal']['db']['type']
    when 'mysql' then include_recipe "mysql::server"
    when 'postgresql' then include_recipe 'postgresql::server'
  end
else
  case node['drupal']['db']['type']
    when 'mysql' then include_recipe "mysql::client"
    when 'postgresql' then include_recipe 'postgresql::client'
  end
end

case node['drupal']['db']['type']
  when 'mysql'
    execute "install-drupal-privileges-to-mysql" do
      command "/usr/bin/mysql -h #{node['drupal']['db']['host']} -u root -p#{node['mysql']['server_root_password']} < /etc/mysql/drupal-grants.sql"
      action :nothing
    end

    template "/etc/mysql/drupal-grants-mysql.sql" do
      path "/etc/mysql/drupal-grants.sql"
      source "grants.mysql.sql.erb"
      owner "root"
      group "root"
      mode "0600"
      variables(
        :user     => node['drupal']['db']['user'],
        :password => node['drupal']['db']['password'],
        :database => node['drupal']['db']['database'],
        :host => node['drupal']['site']['host']
      )
      notifies :run, "execute[install-drupal-privileges-to-mysql]", :immediately
    end

    execute "create #{node['drupal']['db']['database']} database" do
      command "/usr/bin/mysqladmin -h #{node['drupal']['db']['host']} -u root -p#{node['mysql']['server_root_password']} create #{node['drupal']['db']['database']}"
      not_if "mysql -h #{node['drupal']['db']['host']} -u root -p#{node['mysql']['server_root_password']} --silent --skip-column-names --execute=\"show databases like '#{node['drupal']['db']['database']}'\" | grep #{node['drupal']['db']['database']}"
    end

  when 'postgresql'
    execute "install-drupal-privileges-to-postgresql" do
      command "export PGPASSWORD=#{node[:postgresql][:password][:postgres]} && psql -h #{node['drupal']['db']['host']} -p #{node['drupal']['db']['port']} -U postgres  < /tmp/grants.sql"
      action :nothing
    end

    template "/tmp/grants.sql" do
      path "/tmp/grants.sql"
      source "grants.pgsql.sql.erb"
      # owner "root"
      # group "root"
      mode "0600"
      variables(
        :user     => node['drupal']['db']['user'],
        :password => node['drupal']['db']['password'],
        :database => node['drupal']['db']['database']
      )
      notifies :run, "execute[install-drupal-privileges-to-postgresql]", :immediately
    end
end


case node['drupal']['db']['type']
  when 'mysql'
    execute "download-and-install-drupal-to-mysql" do
      cwd  File.dirname(node['drupal']['dir'])
      command "#{node['drupal']['drush']['dir']}/drush -y dl drupal-#{node['drupal']['version']} --destination=#{File.dirname(node['drupal']['dir'])} --drupal-project-rename=#{File.basename(node['drupal']['dir'])} && \
      #{node['drupal']['drush']['dir']}/drush -y site-install -r #{node['drupal']['dir']} --account-name=#{node['drupal']['site']['admin']} --account-pass=#{node['drupal']['site']['pass']} --site-name=\"#{node['drupal']['site']['name']}\" \
      --db-url=mysql://#{node['drupal']['db']['user']}:#{node['drupal']['db']['password']}@#{node['drupal']['db']['host']}/#{node['drupal']['db']['database']}"
      # not_if "#{node['drupal']['drush']['dir']}/drush -r #{node['drupal']['dir']} status | grep #{node['drupal']['version']}"
    end
  when 'postgresql'
    execute "download-and-install-drupal-to-postgresql" do
      cwd  File.dirname(node['drupal']['dir'])
      command "#{node['drupal']['drush']['dir']}/drush -y dl drupal-#{node['drupal']['version']} --destination=#{File.dirname(node['drupal']['dir'])} --drupal-project-rename=#{File.basename(node['drupal']['dir'])} && \
      #{node['drupal']['drush']['dir']}/drush -y site-install -r #{node['drupal']['dir']} --account-name=#{node['drupal']['site']['admin']} --account-pass=#{node['drupal']['site']['pass']} --site-name=\"#{node['drupal']['site']['name']}\" \
      --db-url=pgsql://#{node['drupal']['db']['user']}:#{node['drupal']['db']['password']}@#{node['drupal']['db']['host']}:#{node['drupal']['db']['port']}/#{node['drupal']['db']['database']}"
      # not_if "#{node['drupal']['drush']['dir']}/drush -r #{node['drupal']['dir']} status | grep #{node['drupal']['version']}"
    end
end

if node.has_key?("ec2")
  server_fqdn = node['ec2']['public_hostname']
else
  server_fqdn = node['fqdn']
end

directory "#{node['drupal']['dir']}/sites/default/files" do
  mode "0777"
  action :create
end

if node['drupal']['modules']
  node['drupal']['modules'].each do |m|
    if m.is_a?Array
      drupal_module m.first do
        version m.last
        dir node['drupal']['dir']
      end
    else
      drupal_module m do
        dir node['drupal']['dir']
      end
    end
  end
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
