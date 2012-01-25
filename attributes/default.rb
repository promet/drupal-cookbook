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

default[:drupal][:version] = "7.10"
default[:drupal][:checksum] = "de648c9944ef00ccf6af0fd7cee19a950eae613e1fa7c75dacbe56e4820c8eba"
default[:drupal][:dir] = "/var/www/drupal"
default[:drupal][:db][:database] = "drupal"
default[:drupal][:db][:user] = "drupal"
default[:drupal][:site][:admin] = "admin"
default[:drupal][:site][:pass] = "drupaladmin"
default[:drupal][:site][:name] = "Drupal7"

::Chef::Node.send(:include, Opscode::OpenSSL::Password)

set_unless[:drupal][:db][:password] = secure_password
default[:drupal][:src] = Chef::Config[:file_cache_path]

default[:drupal][:drush][:version] = "4.x-dev"
default[:drupal][:drush][:checksum] = "86bf384f5d70793a6f41d0e4a0d25fa1dceaccb17c9f7db1c5bf0397be6ab64a"
default[:drupal][:drush][:dir] = "/usr/local/drush"

default[:drupal][:modules] = ["views", "webform"]

