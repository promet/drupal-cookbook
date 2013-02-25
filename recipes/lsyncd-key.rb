# Cookbook Name:: drupal
# Recipe:: lsyncd-key
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
drupal_secrets = Chef::EncryptedDataBagItem.load("secrets", "drupal")

include_recipe "build-essential"
chef_gem "ruby-shadow"

user node['drupal']['system']['user'] do
  home node['drupal']['system']['home']
  shell "/bin/bash"
  password node['drupal']['system']['pass_hash']
end

directory "#{node['drupal']['system']['home']}/.ssh" do
  owner node['drupal']['system']['user']
  group node['drupal']['system']['user']
  mode "0700"
  action :create
  recursive true
end
template "#{node['drupal']['system']['home']}/.ssh/authorized_keys2" do
  owner node['drupal']['system']['user']
  group node['drupal']['system']['user']
  mode "0600"
  source "authorized_keys2.erb"
  variables( :pub_key => drupal_secrets['lsyncd']['user']['ssh_pub_key'] )
  action :create
end
template "#{node['drupal']['system']['home']}/.ssh/id_rsa.lsyncd" do
  owner node['drupal']['system']['user']
  group node['drupal']['system']['user']
  mode "0600"
  source "id_rsa.lsyncd.erb"
  variables( :priv_key => drupal_secrets['lsyncd']['user']['ssh_private_key'] )
  action :create
end
