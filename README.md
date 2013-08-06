Description
===========

Installs and configures Drupal; it creates the drupal db user, db password and the database.

Requirements
============

## Platform:

Tested on Debian Wheezy. As long as the required cookbooks work
(php, php-fpm, apache/nginx, mysql/postgres) it should work just fine on any
other distributions.

## Cookbooks:

Opscode cookbooks (http://github.com/opscode/cookbooks/tree/master)

* php
* apache2
* mysql
* openssl (used to generate the secure random drupal db password)
* firewall
* php-fpm
* nginx
* postgresql
* postfix (optional)
* cron (optional)

# ATTRIBUTES:

* drupal[:webserver] - webserver to use (:default: apache, can be nginx)
* drupal[:dir] - location to copy the drupal files. (default: /var/www/drupal)
* drupal[:db][:type] - drupal database type (default: mysql, can be postgresql)
* drupal[:db][:database] - drupal database (default: drupal)
* drupal[:db][:user] - drupal db user (default: drupal)
* drupal[:db][:host] - durpal db host (default: localhost)
* drupal[:db][:password] - drupal db password (randomly generated if not defined)
* drupal[:db][:site][:admin] - drupal admin name (default: admin)
* drupal[:db][:site][:pass] - drupal admin password (drupaladmin)

* drupal[:version] - version of drupal to download and install (default: 7.22)
* drupal[:src] - where to place the drupal source tarball (default: Chef::Config[:file_cache_path])
* drupal[:drush][:version] - version of drush to download (default: 7.x-5.9)
* drupal[:drush][:checksum] - sha256sum of the drush tarball
* drupal[:drush][:dir] - where to install the drush file. (default: /usr/local/drush)

# USAGE:

Include the drupal recipe to install drupal on your system; this will enable also the drupal cron:

  include_recipe "drupal"

Further information is present in the metadata.rb file.

# Note:

Some ideas and naming convenvions were taken from the drupal-cookbok by RiotGames (https://github.com/RiotGames/drupal-cookbook)

License and Author
==================

Author:: Marius Ducea (marius@promethost.com)
Contributor:: Gabor Bognar (gbognar@seisachtheia.com)
Copyright:: 2010-2012, Promet Solutions

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
