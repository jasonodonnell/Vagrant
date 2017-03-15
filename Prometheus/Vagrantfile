# -*- mode: ruby -*-
# # vi: set ft=ruby :

# Specify minimum Vagrant version and Vagrant API version
Vagrant.require_version ">= 1.6.0"
VAGRANTFILE_API_VERSION = "2"

# Require YAML module
require 'yaml'

# Read YAML file with box details
servers = YAML.load_file('servers.yaml')

# Create boxes
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
    servers.each do |servers|
        config.vm.define servers["name"] do |srv|
            srv.vm.box = servers["box"]
            srv.vm.network "private_network", ip: servers["ip"]
            srv.vm.hostname = servers["hostname"]
            srv.vm.box = "centos/7"
            srv.vm.provider :virtualbox do |vb|
                vb.name = servers["name"]
                vb.memory = servers["ram"]
            end

            srv.vm.provision "shell", inline: <<-SHELL
                echo "Building #{servers['name']}.."
                echo "Installing epel.."
                sudo yum -y install epel-release >/dev/null 2>&1
                echo "Updating yum.."
                sudo yum -y update >/dev/null 2>&1
                echo "Installing go vim git wget unzip.."
                sudo yum -y install go vim git wget unzip >/dev/null 2>&1
            SHELL

            Dir["services/#{servers['job']}/*"].each do |fname|
                srv.vm.provision :file do |file|
                    file.source = fname
                    file.destination = "/tmp/#{servers['job']}/" + File.basename(fname)
                end
            end
            
            Dir["services/common/*"].each do |fname|
                srv.vm.provision :file do |file|
                    file.source = fname
                    file.destination = "/tmp/common/" + File.basename(fname)
                end
            end
            srv.vm.provision "shell", inline: <<-SHELL
                echo "Running bootstrap.."
                sudo "/tmp/#{servers['job']}/scripts/bootstrap.sh"
            SHELL
        end
    end
end
