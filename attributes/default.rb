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

default['drupal']['version'] = "7.18"
default['drupal']['dir'] = "/var/www/drupal"
default['drupal']['db']['database'] = "drupal"
default['drupal']['db']['user'] = "drupal"
default['drupal']['db']['host'] = "localhost"
default['drupal']['site']['admin'] = "admin"
default['drupal']['site']['pass'] = "drupaladmin"
default['drupal']['site']['name'] = "Drupal7"
default['drupal']['site']['host'] = "localhost"
default['drupal']['apache']['port'] = "80"

::Chef::Node.send(:include, Opscode::OpenSSL::Password)

set_unless['drupal']['db']['password'] = secure_password
default['drupal']['src'] = Chef::Config[:file_cache_path]

default['drupal']['drush']['version'] = "7.x-5.8"
default['drupal']['drush']['checksum'] = "15dd85f04c49b4a896b02dd6960d3140f3ae680bab3eea5d3aba27be0481e480"
default['drupal']['drush']['dir'] = "/usr/local/drush"

default['drupal']['modules'] = ["views", "webform"]

