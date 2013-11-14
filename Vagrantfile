# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.hostname = "drupal-berkshelf"

  config.vm.box = "opscode-ubuntu-13.04"
  config.vm.box_url = "https://opscode-vm-bento.s3.amazonaws.com/vagrant/opscode_ubuntu-13.04_provisionerless.box"

  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "512"]
  end

  config.vm.network :private_network, ip: "33.33.33.11"

  config.vm.provision :shell, :inline => "sudo aptitude update"

  config.ssh.max_tries = 40
  config.ssh.timeout   = 120

  config.omnibus.chef_version = :latest
  config.berkshelf.enabled = true

  config.vm.provision :chef_solo do |chef|
    chef.json = {
      :www_root => '/vagrant/public',
      :mysql => {
        :server_root_password => "rootpass",
        :server_repl_password => "replpass",
        :server_debian_password => "debpass"
      },
      :postgresql => {
        :password => {
          :postgres => "postgres"
        }
      },
      :drupal => {
        :db => {
          :password => "drupalpass",
          :type => "postgresql" # mysql|postgresql
        },
        # :dir => "/vagrant/mysite",
        :webserver => "nginx", # apache|nginx
      },
      :hosts => {
        :localhost_aliases => ["drupal.vbox.local", "dev-site.vbox.local"]
      }
    }
    chef.log_level = :debug
    chef.run_list = [
      "recipe[drupal::default]"
    ]
  end
end
