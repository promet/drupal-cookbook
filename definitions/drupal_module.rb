#
# Author:: Marius Ducea (marius@promethost.com)
# Cookbook Name:: drupal
# Definition:: drupal_module
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

define :drupal_module, :action => :install, :dir => nil, :version => nil do
  case params[:action]
    when :install
      if params[:dir] == nil then
        log("drupal_module_install requires a working drupal dir") { level :fatal }
        raise "drupal_module_install requires a working drupal dir"
      end
      execute "drush_dl_module #{params[:name]}" do
        cwd params[:dir]
        command "#{node['drupal']['drush']['dir']}/drush -y dl #{params[:name]}"
        not_if "#{node['drupal']['drush']['dir']}/drush -r #{params[:dir]} pm-list |grep '(#{params[:name]})' |grep '#{params[:version]}'"
        #action :nothing
        #subscribes :run, "execute[configure-drupal]", :delayed
      end
      execute "drush_en_module #{params[:name]}" do
        cwd params[:dir]
        command "#{node['drupal']['drush']['dir']}/drush -y en #{params[:name]}"
        not_if "#{node['drupal']['drush']['dir']}/drush -r #{params[:dir]} pm-list |grep '(#{params[:name]})' |grep -i 'enabled'"
        #action :nothing
        #subscribes :run, "execute[drush_en_module #{params[:name]}]", :delayed
      end
    else
      log "drupal_source action #{params[:name]} is unrecognized."
  end
end

