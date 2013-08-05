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

# Exit codes
UNSUPPORTED_WEBSERVER = 1
UNSUPPORTED_DATABASE = 2

unless %w(apache nginx).include? node['drupal']['webserver']
  Chef::Application.fatal!(
    "The webserver #{node['drupal']['webserver']} is not supported.",
    UNSUPPORTED_WEBSERVER
  )
end
unless %w(mysql postgresql).include? node['drupal']['db']['type']
  Chef::Application.fatal!(
    "The database #{node['drupal']['db']['type']} is not supported. ",
    UNSUPPORTED_DATABASE
  )
end


if node['drupal']['webserver'] == 'apache'
  include_recipe %w{
      apache2
      apache2::mod_php5
      apache2::mod_rewrite
      apache2::mod_expires
    }
elsif node['drupal']['webserver'] == 'nginx'
  include_recipe %w{
      nginx
      php-fpm
    }
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
  when 'mysql'
    include_recipe 'php::module_mysql'
  when 'postgresql'
    include_recipe 'php::module_pgsql'
end


if node['drupal']['site']['host'] == 'localhost'
  case node['drupal']['db']['type']
    when 'mysql'
      include_recipe 'mysql::server'
    when 'postgresql'
      include_recipe 'postgresql::server'
  end
else
  case node['drupal']['db']['type']
    when 'mysql'
      include_recipe 'mysql::client'
    when 'postgresql'
      include_recipe 'postgresql::client'
  end
end

execute 'install-drupal-privileges-to-mysql' do
  only_if {node['drupal']['db']['type'] == 'mysql'}
  command <<-CMD
    /usr/bin/mysql \
    -h #{node['drupal']['db']['host']} \
    -u root \
    -p#{node['mysql']['server_root_password']} \
    < /etc/mysql/drupal-grants.sql
    CMD
  action :nothing
end
template '/etc/mysql/drupal-grants-mysql.sql' do
  only_if {node['drupal']['db']['type'] == 'mysql'}
  path '/etc/mysql/drupal-grants.sql'
  source 'grants.mysql.sql.erb'
  owner 'root'
  group 'root'
  mode '0600'
  variables(
    :user     => node['drupal']['db']['user'],
    :password => node['drupal']['db']['password'],
    :database => node['drupal']['db']['database'],
    :host => node['drupal']['site']['host']
  )
  notifies :run, 'execute[install-drupal-privileges-to-mysql]', :immediately
end
execute "create #{node['drupal']['db']['database']} database" do
  only_if {node['drupal']['db']['type'] == 'mysql'}
  not_if <<-COND
    mysql \
    -h #{node['drupal']['db']['host']} \
    -u root \
    -p#{node['mysql']['server_root_password']} \
    --silent \
    --skip-column-names \
    --execute="show databases like '#{node['drupal']['db']['database']}'"\
    | grep #{node['drupal']['db']['database']}
    COND
  command <<-CMD
    /usr/bin/mysqladmin \
    -h #{node['drupal']['db']['host']} \
    -u root \
    -p#{node['mysql']['server_root_password']} \
    create #{node['drupal']['db']['database']}
    CMD
end


execute 'install-drupal-privileges-to-postgresql' do
  only_if {node['drupal']['db']['type'] == 'postgresql'}
  command <<-CMD
    export PGPASSWORD=#{node['postgresql']['password']['postgres']} \
    && \
    psql -h #{node['drupal']['db']['host']} \
      -p #{node['drupal']['db']['port']} \
      -U postgres  < /tmp/grants.sql
    CMD
  action :nothing
end
template "/tmp/grants.sql" do
  only_if {node['drupal']['db']['type'] == 'postgresql'}
  path '/tmp/grants.sql'
  source 'grants.pgsql.sql.erb'
  mode '0600'
  variables(
    :user     => node['drupal']['db']['user'],
    :password => node['drupal']['db']['password'],
    :database => node['drupal']['db']['database']
  )
  notifies :run, 'execute[install-drupal-privileges-to-postgresql]', :immediately
end

include_recipe 'drupal::drush'

execute 'download-and-install-drupal-to-mysql' do
  only_if {node['drupal']['db']['type'] == 'mysql'}
  not_if <<-COND
    #{node['drupal']['drush']['dir']}/drush \
      -r #{node['drupal']['dir']} status \
      | grep #{node['drupal']['version']}
    COND
  cwd File.dirname(node['drupal']['dir'])
  command <<-CMD
    #{node['drupal']['drush']['dir']}/drush \
      -y dl drupal-#{node['drupal']['version']} \
      --destination=#{File.dirname(node['drupal']['dir'])} \
      --drupal-project-rename=#{File.basename(node['drupal']['dir'])} \
      && \
    #{node['drupal']['drush']['dir']}/drush \
      -y site-install \
      -r #{node['drupal']['dir']} \
      --account-name=#{node['drupal']['site']['admin']} \
      --account-pass=#{node['drupal']['site']['pass']} \
      --site-name=\"#{node['drupal']['site']['name']}\" \
      --db-url="mysql://#{node['drupal']['db']['user']}:#{node['drupal']['db']['password']}@#{node['drupal']['db']['host']}:#{node['drupal']['db']['port']}/#{node['drupal']['db']['database']}"
    CMD
end

execute 'download-and-install-drupal-to-postgresql' do
  only_if {node['drupal']['db']['type'] == 'postgresql'}
  not_if <<-COND
    #{node['drupal']['drush']['dir']}/drush \
      -r #{node['drupal']['dir']} status \
      | grep #{node['drupal']['version']}
    COND
  cwd  File.dirname(node['drupal']['dir'])
  command <<-CMD
    #{node['drupal']['drush']['dir']}/drush \
      -y dl drupal-#{node['drupal']['version']} \
      --destination=#{File.dirname(node['drupal']['dir'])} \
      --drupal-project-rename=#{File.basename(node['drupal']['dir'])} \
      && \
    #{node['drupal']['drush']['dir']}/drush \
      -y site-install \
      -r #{node['drupal']['dir']} \
      --account-name=#{node['drupal']['site']['admin']} \
      --account-pass=#{node['drupal']['site']['pass']} \
      --site-name=\"#{node['drupal']['site']['name']}\" \
      --db-url="pgsql://#{node['drupal']['db']['user']}:#{node['drupal']['db']['password']}@#{node['drupal']['db']['host']}:#{node['drupal']['db']['port']}/#{node['drupal']['db']['database']}"
    CMD
end

if node.has_key?('ec2')
  server_fqdn = node['ec2']['public_hostname']
else
  server_fqdn = node['fqdn']
end

directory "#{node['drupal']['dir']}/sites/default/files" do
  mode '0777'
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


if node['drupal']['webserver'] == 'apache'
  web_app 'drupal' do
    template 'drupal.conf.apache.erb'
    docroot node['drupal']['dir']
    server_name server_fqdn
    server_aliases node['fqdn']
  end
  execute 'disable-default-site' do
    only_if { File.exists? "#{node['apache']['dir']}/sites-enabled/default" }
    command 'sudo a2dissite default'
    notifies :reload, 'service[apache2]', :delayed
  end
end

if node['drupal']['webserver'] == 'nginx'
  template 'drupal.conf.nginx.erb' do
    path "#{node['nginx']['dir']}/sites-available/drupal"
    source 'drupal.conf.nginx.erb'
    user node['drupal']['nginx']['user']
    group node['drupal']['nginx']['group']
    mode 00644
    variables(
      :server_port => node['drupal']['nginx']['port'],
      :server_name => node['drupal']['nginx']['server_name'],
      :location => node['drupal']['nginx']['location'],
      :location_root => node['drupal']['dir'],
      :fast_cgi_pass => node['drupal']['nginx']['fast_cgi_pass']
    )
    action :create
  end
  fpm_pool 'drupal' do
    user node['php-fpm']['pool']['drupal']['user']
    group node['php-fpm']['pool']['drupal']['group']
  end
  nginx_site 'drupal' do
    enable true
  end
end

if node['with_cron']
  include_recipe 'drupal::cron'
end

if node['with_postfix']
  include_recipe 'postfix'
end

