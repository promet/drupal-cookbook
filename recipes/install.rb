#
# Author:: Marius Ducea (marius@promethost.com)
# Cookbook Name:: drupal
# Recipe:: install
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

include_recipe "drupal::default"

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

execute "create #{node['drupal']['db']['database']} database" do
  command "/usr/bin/mysqladmin -h #{node['drupal']['db']['host']} -u root -p#{node['mysql']['server_root_password']} create #{node['drupal']['db']['database']}"
  not_if "mysql -h #{node['drupal']['db']['host']} -u root -p#{node['mysql']['server_root_password']} --silent --skip-column-names --execute=\"show databases like '#{node['drupal']['db']['database']}'\" | grep #{node['drupal']['db']['database']}"
end

execute "install-drupal" do
  cwd  File.dirname(node['drupal']['dir'])
  user node['drupal']['system']['user']
  command "#{node['drupal']['drush']['dir']}/drush -y site-install -r #{node['drupal']['dir']} --account-name=#{node['drupal']['site']['admin']} --account-pass=#{node['drupal']['site']['pass']} --site-name=\"#{node['drupal']['site']['name']}\" \
  --db-url=mysql://#{node['drupal']['db']['user']}:'#{node['drupal']['db']['password']}'@#{node['drupal']['db']['host']}/#{node['drupal']['db']['database']} #{node['drupal']['drush']['options']}"
  not_if "test -f #{node['drupal']['dir']}/sites/default/settings.php"
  retries 3
end

if node.has_key?("ec2")
  server_fqdn = node['ec2']['public_hostname']
else
  server_fqdn = node['fqdn']
end

directory "#{node['drupal']['dir']}/sites/default/files" do
  case node['platform']
  when "debian", "ubuntu"
    group "www-data"
  when "centos", "redhat", "amazon", "scientific"
    group "apache"
  end
  mode "0775"
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
