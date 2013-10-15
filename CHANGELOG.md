Drupal Cookbook CHANGELOG
======================
This file is used to list changes made in each version of the drupal cookbook.

## v1.1.16
------
### Bug
- Fix dependencies of sites/default/files/settings.php

## v1.1.15
------
### Bug
- Fix fatal log for sites/default/settings.php from sites/default/files/settings.php

## v1.1.14
------
### Improvement
- Allow template to be created and maintained without triggering repeated site installs!

## v1.1.13
------
### Improvement
- Modules will not install until the site-install is complete and was successful

## v1.1.12
------
### Improvement
- Creating the settings.php based on Drupal unpack chain has pitfalls. Let's just create it if it is missing.

## v1.1.11
------
### Bug
- Set rx on all directories of the DocumentRoot path

## v1.1.10:

* Finetune the Drupal docroot file and directory permissions

## v1.1.9:

* Standardize the default[:drupal][:db] array

## v1.1.8:

* Set Drupal docroot permissions correctly
* Allow web_app to be disabled

## v1.1.7:

* Correct hostsfile_entry name
* ctools module installed by default because of webform
* patches support

## v1.1.6:

* hostsfile to manage /etc/hosts

## v1.1.5:

* Rework dependencies and sequence to support non-root credentials for mysql
* Set permissions on docroot
* Restart Apache if necessary

## v1.1.4:

* Allow us to use another drush cookbook

## v1.1.3:

* Don't install drush by default

## v1.1.2:

* Default to 7.23
* Consider 127.0.0.1 localhost also
* 

## v1.1.0:

* fix bug caused by the removal of `mysql_database` LWRP from the mysql cookbook starting with version 1.2.0
* fix most foodcritic warnings
* upgrade to the latest stable branch for drush: 7.x-5.4
* installing by default latest stable drupal version 7.14

## v1.0.0:

* dropping support for drupal6.x; this requires drupal7 for the install to work
