# <a name="title"></a> drupal-cookbook [![Build Status](https://secure.travis-ci.org/cdracars/drupal-cookbook.png)](http://travis-ci.org/cdracars/drupal-cookbook)

Description
===========

Installs and configures Drupal; it creates the drupal db user, db password and the database;
You will need to manually complete the installation step by visiting http://<server_fqdn>/install.php

Requirements
============

## Platform:

Tested on Ubuntu 10.04, Debian Lenny. As long as the required cookbooks work (apache, php, mysql) it
should work just fine on any other distributions.

## Cookbooks:

Opscode cookbooks (http://github.com/opscode/cookbooks/tree/master)

* mysql
* php
* apache2
* openssl (used to generate the secure random drupal db password)

# ATTRIBUTES:

* drupal[:version] - version of drupal to download and install (default: 6.19)
* drupal[:checksum] - sha256sum of the source tarball
* drupal[:dir] - location to copy the drupal files. (default: /var/www/drupal)
* drupal[:db][:database] - drupal database (default: drupal)
* drupal[:db][:user] - drupal db user (default: drupal)
* drupal[:db][:password] - drupal db password (randomly generated if not defined)
* drupal[:src] - where to place the drupal source tarball (default: Chef::Config[:file_cache_path])

* drupal[:drush][:version] - version of drush to download (default: 3.3)
* drupal[:drush][:checksum] - sha256sum of the drush tarball
* drupal[:drush][:dir] - where to install the drush file. (default: /usr/local/drush)

# USAGE:

Include the drupal recipe to install drupal on your system; this will enable also the drupal cron:

  include_recipe "drupal"

Include the drush recipe to install drush:

  include_recipe "drupal::drush"

If you want to install a different version you just have to customize the version attribute and checksum
(sha256 checksum on the source)

License and Author
==================

Author:: Marius Ducea (marius@promethost.com)

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
