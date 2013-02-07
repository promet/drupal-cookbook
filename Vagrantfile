require 'berkshelf/vagrant'

Vagrant::Config.run do |config|
  config.vm.host_name = "drupal-berkshelf"

  config.vm.box = "opscode-ubuntu-12.04"
  config.vm.box_url = "https://opscode-vm.s3.amazonaws.com/vagrant/boxes/opscode-ubuntu-12.04.box"

  config.vm.customize ["modifyvm", :id, "--memory", "512"]

  config.vm.network :hostonly, "33.33.33.11"

  config.vm.forward_port 80, 8080
  config.vm.share_folder("v-root", "/vagrant", ".")

  config.vm.provision :shell, :inline => "sudo aptitude update"

  config.ssh.max_tries = 40
  config.ssh.timeout   = 120

  config.vm.provision :chef_solo do |chef|
    chef.json = {
     :www_root => '/vagrant/public',
     :mysql => {
        :server_root_password => "rootpass",
        :server_repl_password => "replpass",
        :server_debian_password => "debpass"
     },
     :drupal => {
        :db => {
          :password => "drupalpass"
        },
        :dir => "/vagrant/mysite"
      },
      :hosts => {
        :localhost_aliases => ["drupal.vbox.local", "dev-site.vbox.local"]
      }  
    }

    chef.run_list = [
      "recipe[drupal::default]"
    ]
  end
end
