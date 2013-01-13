maintainer       "Promet Solutions"
maintainer_email "marius@promethost.com"
license          "Apache 2.0"
name             "drupal"
description      "Installs/Configures drupal"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "1.1.1"
recipe           "drupal", "Installs and configures Drupal"
recipe           "drupal::cron", "Sets up the default drupal cron"
recipe           "drupal::drush", "Installs drush - a command line shell and scripting interface for Drupal"

%w{ postfix php apache2 mysql openssl }.each do |cb|
  depends cb
end

%w{ debian ubuntu }.each do |os|
  supports os
end

