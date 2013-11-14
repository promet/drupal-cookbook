maintainer       "Seisachtheia"
maintainer_email "gbognar@seisachtheia.com"
license          "Apache 2.0"
name             "drupal"
description      "Installs/Configures drupal"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "2.0.0"
recipe           "drupal", "Installs and configures Drupal"
recipe           "drupal::cron", "Sets up the default drupal cron"
recipe           "drupal::drush",\
  "Installs drush - a command line shell and scripting interface for Drupal"
recipe           "drupal::firewall",\
  "Opens up an interface and ports for http and https on the firewall"

%w{php apache2 mysql openssl firewall cron
  php-fpm postgresql postfix
}.each do |cb|
  depends cb
end

depends 'nginx', '>= 2.0'

%w{ debian ubuntu }.each do |os|
  supports os
end


attribute 'drupal/webserver',
  :display_name => 'Webserver type',
  :description => 'The webserver to run Drupal',
  :choice => ['apache','nginx'],
  :type => 'string',
  :required => 'recommended',
  :recipes => ['drupal::default'],
  :default => 'apache'
attribute 'drupal/port',
  :display_name => 'Webserver port',
  :description => 'The port of the webserver to serve Drupal content',
  :type => 'string',
  :required => 'recommended',
  :recipes => ['drupal::default'],
  :default => '80'
attribute 'drupal/db/type',
  :display_name => 'Type of database to use',
  :description => 'The port of the webserver to serve Drupal content',
  :choice => ['mysql','postgresql'],
  :type => 'string',
  :required => 'recommended',
  :recipes => ['drupal::default'],
  :default => 'mysql'
attribute 'with_postfix',
  :display_name => 'Install postfix?',
  :description => 'If true/yes, postfix will be installed',
  :choice => ['true','false'],
  :type => 'string',
  :required => 'optional',
  :recipes => ['drupal::default'],
  :default => 'false'
attribute 'with_cron',
  :display_name => 'Set cron jobs?',
  :description => 'If true/yes, Drupal-related cron jobs will be set',
  :choice => ['true','false'],
  :type => 'string',
  :required => 'optional',
  :recipes => ['drupal::default'],
  :default => 'false'
attribute 'drupal/version',
  :display_name => 'Drupal version',
  :description => 'Version of Drupal to be installed',
  :type => 'string',
  :required => 'optional',
  :recipes => ['drupal::default'],
  :default => '7.22'
attribute 'drupal/dir',
  :display_name => 'Drupal directory',
  :description => 'The directory Drupal will be installed to',
  :type => 'string',
  :required => 'optional',
  :recipes => ['drupal::default'],
  :default => '/var/www/drupal'
attribute 'drupal/db/database',
  :display_name => 'Drupal database',
  :description => 'The name of the database to be used by Drupal',
  :type => 'string',
  :required => 'optional',
  :recipes => ['drupal::default'],
  :default => 'drupal'
attribute 'drupal/db/user',
  :display_name => 'Drupal database user',
  :description => 'The name of the database user to be used by Drupal',
  :type => 'string',
  :required => 'optional',
  :recipes => ['drupal::default'],
  :default => 'drupal'
attribute 'drupal/db/host',
  :display_name => 'Drupal database host',
  :description => 'The host running the database to be used by Drupal',
  :type => 'string',
  :required => 'optional',
  :recipes => ['drupal::default'],
  :default => 'localhost'
attribute 'drupal/site/admin',
  :display_name => 'Drupal admin name',
  :description => 'The name for the Drupal site administrator account',
  :type => 'string',
  :required => 'recommended',
  :recipes => ['drupal::default'],
  :default => 'admin'
attribute 'drupal/site/pass',
  :display_name => 'Drupal admin password',
  :description => 'The password for the Drupal site administrator account',
  :type => 'string',
  :required => 'recommended',
  :recipes => ['drupal::default'],
  :default => 'drupaladmin'
attribute 'drupal/site/name',
  :display_name => 'Drupal site name',
  :description => 'The name for the Drupal site',
  :type => 'string',
  :required => 'recommended',
  :recipes => ['drupal::default'],
  :default => 'Drupal7'
attribute 'drupal/site/host',
  :display_name => 'Drupal site host',
  :description => 'The name for the host hosting the Drupal site',
  :type => 'string',
  :required => 'recommended',
  :recipes => ['drupal::default'],
  :default => 'localhost'
attribute 'drupal/modules',
  :display_name => 'Drupal modules',
  :description => 'The Drupal modules to be installed',
  :type => 'array',
  :required => 'optional',
  :recipes => ['drupal::default'],
  :default => ['views', 'webform']
attribute 'drupal/nginx/server_name',
  :display_name => 'Server name for Nginx',
  :description => 'The name of the Nginx server running Drupal',
  :type => 'string',
  :required => 'optional',
  :recipes => ['drupal::default'],
  :default => 'localhost'
attribute 'drupal/nginx/user',
  :display_name => 'Nginx user',
  :description => 'The user running Nginx',
  :type => 'string',
  :required => 'optional',
  :recipes => ['drupal::default'],
  :default => 'vagrant'
attribute 'drupal/nginx/group',
  :display_name => 'Nginx group',
  :description => 'The group running Nginx',
  :type => 'string',
  :required => 'optional',
  :recipes => ['drupal::default'],
  :default => 'vagrant'
attribute 'drupal/nginx/location',
  :display_name => 'Nginx location',
  :description => 'Location from which Drupal is served when using Nginx',
  :type => 'string',
  :required => 'optional',
  :recipes => ['drupal::default'],
  :default => '/'
attribute 'php-fpm/pools',
  :display_name => 'PHP-FPM pools for Nginx',
  :description => 'PHP-FPM pools to be run when using Nginx',
  :type => 'array',
  :required => 'optional',
  :recipes => ['drupal::default'],
  :default => ['drupal']
attribute 'php-fpm/pool/drupal/user',
  :display_name => 'Drupal PHP-FPM pool user for Nginx',
  :description => 'User running the PHP-FPM pool for Drupal when using Nginx',
  :type => 'string',
  :required => 'optional',
  :recipes => ['drupal::default'],
  :default => 'vagrant'
attribute 'php-fpm/pool/drupal/group',
  :display_name => 'Drupal PHP-FPM pool group for Nginx',
  :description => 'Group running the PHP-FPM pool for Drupal when using Nginx',
  :type => 'string',
  :required => 'optional',
  :recipes => ['drupal::default'],
  :default => 'vagrant'
attribute 'php-fpm/pool/drupal/listen',
  :display_name => 'Drupal PHP-FPM pool link',
  :description => 'Connection between Drupal PHP-FPM pool and Nginx',
  :type => 'string',
  :required => 'optional',
  :recipes => ['drupal::default'],
  :default => '/var/run/php-fpm-drupal.sock'
attribute 'php-fpm/pool/drupal/allowed_clients',
  :display_name => 'Drupal PHP-FPM allowed_clients',
  :description => 'The allowed_clients setting for the Drupal PHP-FPM pool',
  :type => 'array',
  :required => 'optional',
  :recipes => ['drupal::default'],
  :default => []
attribute 'php-fpm/pool/drupal/process_manager',
  :display_name => 'Drupal PHP-FPM process_manager type',
  :description => 'The pm setting for the Drupal PHP-FPM pool',
  :choice => ['dynamic','static'],
  :type => 'string',
  :required => 'optional',
  :recipes => ['drupal::default'],
  :default => 'dynamic'
attribute 'php-fpm/pool/drupal/max_children',
  :display_name => 'Drupal PHP-FPM process_manager maximum children',
  :description => 'The pm.max_children setting for the Drupal PHP-FPM pool',
  :type => 'string',
  :required => 'optional',
  :recipes => ['drupal::default'],
  :default => '5'
attribute 'php-fpm/pool/drupal/start_servers',
  :display_name => 'Drupal PHP-FPM process_manager servers to start',
  :description => 'The pm.start_servers setting for the Drupal PHP-FPM pool',
  :type => 'string',
  :required => 'optional',
  :recipes => ['drupal::default'],
  :default => '2'
attribute 'php-fpm/pool/drupal/min_spare_servers',
  :display_name => 'Minimum spare servers for the Drupal PHP-FPM pool',
  :description => 'The pm.min_spare_servers setting for the Drupal PHP-FPM pool',
  :type => 'string',
  :required => 'optional',
  :recipes => ['drupal::default'],
  :default => '1'
attribute 'php-fpm/pool/drupal/max_spare_servers',
  :display_name => 'Maximum spare servers for the Drupal PHP-FPM pool',
  :description => 'The pm.max_spare_servers setting for the Drupal PHP-FPM pool',
  :type => 'string',
  :required => 'optional',
  :recipes => ['drupal::default'],
  :default => '3'
attribute 'php-fpm/pool/drupal/max_requests',
  :display_name => 'Maximum requests for the Drupal PHP-FPM pool',
  :description => 'The pm.max_requests setting for the Drupal PHP-FPM pool',
  :type => 'string',
  :required => 'optional',
  :recipes => ['drupal::default'],
  :default => '500'
attribute 'drupal/drush/version',
  :display_name => 'Drush version',
  :description => 'Version of Drush to be used',
  :type => 'string',
  :required => 'optional',
  :recipes => ['drupal::default'],
  :default => '7.x-5.9'
attribute 'drupal/drush/checksum',
  :display_name => 'Drush checksum',
  :description => 'SHA256 cheksum of the Drush src',
  :type => 'string',
  :required => 'optional',
  :recipes => ['drupal::default'],
  :default => '3acc2a2491fef987c17e85122f7d3cd0bc99cefd1bc70891ec3a1c4fd51dcceer'
attribute 'drupal/drush/dir',
  :display_name => 'Drush directory',
  :description => 'Directory for Drush',
  :type => 'string',
  :required => 'optional',
  :recipes => ['drupal::default'],
  :default => '/usr/local/drush'
attribute 'drupal/nginx/fast_cgi_pass',
  :display_name => 'Drupal Fast CGI pass',
  :description => 'Fast CGI pass for the Drupal PHP-FPM pool when using Nginx',
  :calculated => true,
  :type => 'string',
  :recipes => ['drupal::default']
attribute 'drupal/db/port',
  :display_name => 'Database port',
  :description => 'The port number of the database to be used',
  :type => 'string',
  :required => 'optional',
  :recipes => ['drupal::default'],
  :calculated => true
attribute 'drupal/apache/port',
  :display_name => 'Apache port',
  :description => 'The port Drupal is served by Apache',
  :type => 'string',
  :required => 'optional',
  :recipes => ['drupal::default'],
  :calculated => true
attribute 'drupal/nginx/port',
  :display_name => 'Nginx port',
  :description => 'The port Drupal is served by Nginx',
  :type => 'string',
  :required => 'optional',
  :recipes => ['drupal::default'],
  :calculated => true
attribute 'drupal/firewall/http',
  :display_name => 'Drupal http port on the firewall',
  :description => 'The port to be opened for Drupal on the firewall for http',
  :type => 'string',
  :required => 'optional',
  :recipes => ['drupal::firewall'],
  :default => '80'
attribute 'drupal/firewall/https',
  :display_name => 'Drupal https port on the firewall',
  :description => 'The port to be opened for Drupal on the firewall for https',
  :type => 'string',
  :required => 'optional',
  :recipes => ['drupal::firewall'],
  :default => '443'
attribute 'drupal/firewall/interface',
  :display_name => 'Drupal interface on the firewall',
  :description => 'The interface to be opened for Drupal on the firewall',
  :type => 'string',
  :required => 'optional',
  :recipes => ['drupal::firewall'],
  :default => 'eth0'

