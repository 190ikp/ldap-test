# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  domain = "example.com"
  dn = "dc=example,dc=com"
  master_node = "server-1"

  num_server = 1
  num_client = 1
  node_cpus = 2
  node_mem = 2048
  
  config.vm.box = "ubuntu/bionic64"

  # config.vm.box_check_update = false
    
  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--ostype", "Ubuntu_64", "--ioapic", "on"]
    vb.cpus = node_cpus
    vb.memory = node_mem
  end

  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box 
  end

  # Use vagrant-hosts plugin for internal DNS
  if Vagrant.has_plugin?("vagrant-hosts")
    config.vm.provision :hosts, :sync_hosts => true
  end
  
  (1..num_server).each do |i|
    config.vm.define "server-#{i}" do |server|
      server.vm.provider "virtualbox" do |vb|
        vb.name = "server-#{i}"
      end

      server.vm.hostname = "server-#{i}." + domain
      server.vm.network "private_network", ip: "10.0.10.#{i+1}", netmask: "255.255.0.0", virtualbox__intnet: true
      # server.vm.provision "shell" do |s|
      #   s.privileged = false
      #   # s.env = {"MASTER" => master_node, "FQDN" => domain}
      #   s.env = {"SRC_DIR" => src_dir}
      #   s.path = "bin/ldap_init.sh" 
      #   s.args = ["server"]
      # end
      # server.vm.provision "shell", privileged: false, inline: <<-SHELL
      #   # copy the cert to LDAP clients
      #   cp /etc/ssl/certs/server.crt /vagrant/
      # SHELL
    end
  end

  (1..num_client).each do |i|
    config.vm.define "client-#{i}" do |client|
      client.vm.provider "virtualbox" do |vb|
        vb.name = "client-#{i}"
      end

      client.vm.hostname = "client-#{i}." + domain
      client.vm.network "private_network", ip: "10.0.20.#{i+1}", netmask: "255.255.0.0", virtualbox__intnet: true
      # client.vm.provision "shell", privileged: false, inline: <<-SHELL
      #   # copy the cert to LDAP clients
      #   sudo cp /vagrant/server.crt /etc/ssl/certs/server.crt
      # SHELL
      # client.vm.provision "shell" do |s|
      #   s.privileged = false
      #   # s.env = {"MASTER" => master_node, "FQDN" => domain, "DN" => dn}
      #   s.env = {"SRC_DIR" => src_dir}
      #   s.path = "bin/ldap_init.sh" 
      #   s.args = ["client"]
      # end
    end
  end
end
