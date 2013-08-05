#
# Author:: Marius Ducea (marius@promethost.com)
# Cookbook Name:: drupal
# Attributes:: drupal
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

default['drupal']['webserver'] = 'apache' # nginx|apache
default['drupal']['port'] = '80'
default['drupal']['db']['type'] = 'mysql' # postgresql|mysql

default['with_postfix'] = false # true|false
default['with_cron'] = false    # true|false

default['drupal']['version'] = '7.22'
default['drupal']['dir'] = '/var/www/drupal'
default['drupal']['db']['database'] = 'drupal'
default['drupal']['db']['user'] = 'drupal'
default['drupal']['db']['host'] = 'localhost'

default['drupal']['site']['admin'] = 'admin'
default['drupal']['site']['pass'] = 'drupaladmin'
default['drupal']['site']['name'] = 'Drupal7'
default['drupal']['site']['host'] = 'localhost'

default['drupal']['modules'] = ['views', 'webform']

default['drupal']['nginx']['server_name'] = 'localhost'
default['drupal']['nginx']['user'] = 'vagrant'
default['drupal']['nginx']['group'] = 'vagrant'
default['drupal']['nginx']['location'] = '/'

default['php-fpm']['pools'] = ['drupal']

default['php-fpm']['pool']['drupal']['user'] = 'vagrant'
default['php-fpm']['pool']['drupal']['group'] = 'vagrant'
default['php-fpm']['pool']['drupal']['listen'] = '/var/run/php-fpm-drupal.sock'
default['php-fpm']['pool']['drupal']['allowed_clients'] = []
default['php-fpm']['pool']['drupal']['process_manager'] = 'dynamic'
default['php-fpm']['pool']['drupal']['max_children'] = 5
default['php-fpm']['pool']['drupal']['start_servers'] = 2
default['php-fpm']['pool']['drupal']['min_spare_servers'] = 1
default['php-fpm']['pool']['drupal']['max_spare_servers'] = 3
default['php-fpm']['pool']['drupal']['max_requests'] = 500

::Chef::Node.send(:include, Opscode::OpenSSL::Password)

set_unless['drupal']['db']['password'] = secure_password
default['drupal']['src'] = Chef::Config[:file_cache_path]

default['drupal']['drush']['version'] = '7.x-5.9'
default['drupal']['drush']['checksum'] = \
  '3acc2a2491fef987c17e85122f7d3cd0bc99cefd1bc70891ec3a1c4fd51dcceer'
default['drupal']['drush']['dir'] = '/usr/local/drush'


if default['php-fpm']['pool']['drupal']['listen'].start_with?('/')
  # Listen to unix pipes
  default['drupal']['nginx']['fast_cgi_pass'] = \
    "unix:#{default['php-fpm']['pool']['drupal']['listen']}"
else
  default['drupal']['nginx']['fast_cgi_pass'] = \
    default['php-fpm']['pool']['drupal']['listen']
end

if default['drupal']['db']['type'] = 'postgresql'
  default['drupal']['db']['port'] = '5432'
else
  default['drupal']['db']['port'] = '3306'
end

default['drupal']['apache']['port'] = default['drupal']['port']
default['drupal']['nginx']['port'] = default['drupal']['port']
default['nginx']['default_site_enabled'] = false
