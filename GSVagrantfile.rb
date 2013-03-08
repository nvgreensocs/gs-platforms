# -*- mode: ruby -*-
# vi: set ft=ruby :

#  -------    GS Project Vagrantfile  --------

# LICENSETEXT
# 
#   Copyright (C) 2012 : GreenSocs Ltd
#       http://www.greensocs.com/ , email: info@greensocs.com
# 
# The contents of this file are subject to the licensing terms specified
# in the file LICENSE. Please consult this file for restrictions and
# limitations that may apply.
# 
# ENDLICENSETEXT

inVagrant = !!Module.const_get('Vagrant') rescue false
if inVagrant

  require 'open-uri'
  require 'fileutils'
  require 'zlib' 
  require 'archive/tar/minitar'
  include Archive::Tar



  class SSHExecuteCommand < Vagrant::Command::Base
    def help
      abort("Usage: vagrant run <command> [options...]")
    end
    def execute
      @main_args, @sub_command, @sub_args = split_main_and_subcommand(@argv)
      help if !@sub_command

      env=Vagrant::Environment.new(:ui_class => Vagrant::UI::Colored)

      topdir=File.dirname(__FILE__).split(Regexp.union(*[File::SEPARATOR, File::ALT_SEPARATOR].compact));
      pwddir = Dir.pwd.split(Regexp.union(*[File::SEPARATOR, File::ALT_SEPARATOR].compact));
      topdir.each { |x|   pwddir=pwddir.drop(1) if pwddir.first == x }

      pwddir=pwddir.join(File::SEPARATOR);

      env.cli("up") if !env.primary_vm.created?
      env.cli("up","--no-provision") if !env.primary_vm.channel.ready?

      command="cd /vagrant/#{pwddir};"+@sub_command + " " + @sub_args.join(" ")
      env.primary_vm.channel.execute(command) do |type, data|
	puts data
      end

    end
  end

  class UpgradeExecuteCommand < Vagrant::Command::Base
    def help
      abort ("Usage: vagrant upgrade [<tarball.tar.gz>]   If the optional tar ball is given, it is used, otherwise a git pull origin master is attempted")
    end
    def execute
      env=Vagrant::Environment.new(:ui_class => Vagrant::UI::Colored)
      http_proxy = ENV['http_proxy'] || ENV['HTTP_PROXY']

      if !open("http://www.greensocs.com/") && !http_proxy
	puts "Please set your http_proxy environment variable"
	exit -1
      end

      @main_args, @tarball, @sub_args = split_main_and_subcommand(@argv)
      #    help if !@tarball || !File.exists?(@tarball)

      dir=File.dirname(__FILE__)
      parentdir=File.dirname(dir)

      env.cli("halt");
      env.cli("destroy");
      
      FileUtils.rm_rf(dir+File::SEPARATOR+"ModelLibrary")

      if @tarball && File.exists?(@tarball)
	tgz = Zlib::GzipReader.new(File.open(@tarball, 'rb'))
	Minitar.unpack(tgz, parentdir)
      else
	IO.popen( <<-EOH
		 cd '#{dir}'
		 git pull origin master
		 git submodule update
		 EOH
		 ) { |f|  f.each_line { |line| puts line } }
      end

      env.boxes.each { |box|  box.destroy }

      exec('vagrant up'); ## Dont simply call env.cli("up") as we want it to re-read this file
    end
  end

  Vagrant.commands.register(:run) { SSHExecuteCommand  }
  Vagrant.commands.register(:upgrade) { UpgradeExecuteCommand }

end

class GSProject
  def initialize(box,cookbooks, versions, toplevel, memory)
    @box=box;
    @cookbooks=cookbooks;
    @versions=versions;
    @toplevel=toplevel;
    @memory=memory;
  end

  def run

    inVagrant = !!Module.const_get('Vagrant') rescue false
    if inVagrant

      Vagrant::Config.run do |config|
	# All Vagrant configuration is done here. The most common configuration
	# options are documented and commented below. For a complete reference,
	# please see the online documentation at vagrantup.com.

	# Every Vagrant virtual environment requires a box to build off of.
	# 64 bit box
	#  config.vm.box = "GreenSocsBaseMachine26Nov12"
	config.vm.box = "#{@box}";

	# The url from where the 'config.vm.box' box will be fetched if it
	# doesn't already exist on the user's system.
	#  config.vm.box_url = "http://www.greensocs.com/files/GreenSocsBaseMachine26Nov12.box"
	config.vm.box_url = "http://www.greensocs.com/files/#{@box}.box";

	# Boot with a GUI so you can see the screen. (Default is headless)
	# config.vm.boot_mode = :gui

	# Assign this VM to a host-only network IP, allowing you to access it
	# via the IP. Host-only networks can talk to the host machine as well as
	# any other machines on the same network, but cannot be accessed (through this
	# network interface) by any external networks.
	# config.vm.network :hostonly, "192.168.33.10"

	# Assign this VM to a bridged network, allowing you to connect directly to a
	# network using the host's network device. This makes the VM appear as another
	# physical device on your network.
	# config.vm.network :bridged


	#    config.vm.network :bridged, { bridge: 'eth0', nic_type: 'virtio', auto_config: false }


	config.vm.customize(["modifyvm", :id, "--nictype1", "virtio"])


	# Forward a port from the guest to the host, which allows for outside
	# computers to access the VM, whereas host only networking does not.
	# config.vm.forward_port 80, 8080

	# Share an additional folder to the guest VM. The first argument is
	# an identifier, the second is the path on the guest to mount the
	# folder, and the third is the path on the host to the actual folder.
	# config.vm.share_folder "v-data", "/vagrant_data", "../data"

	# Enable provisioning with Puppet stand alone.  Puppet manifests
	# are contained in a directory path relative to this Vagrantfile.
	# You will need to create the manifests directory and a manifest in
	# the file base.pp in the manifests_path directory.
	#
	# An example Puppet manifest to provision the message of the day:
	#
	# # group { "puppet":
	# #   ensure => "present",
	# # }
	# #
	# # File { owner => 0, group => 0, mode => 0644 }
	# #
	# # file { '/etc/motd':
	# #   content => "Welcome to your Vagrant-built virtual machine!
	# #               Managed by Puppet.\n"
	# # }
	#
	# config.vm.provision :puppet do |puppet|
	#   puppet.manifests_path = "manifests"
	#   puppet.manifest_file  = "base.pp"
	# end

	# Enable provisioning with chef solo, specifying a cookbooks path, roles
	# path, and data_bags path (all relative to this Vagrantfile), and adding 
	# some recipes and/or roles.
	#
	# config.vm.provision :chef_solo do |chef|
	#   chef.cookbooks_path = "../my-recipes/cookbooks"
	#   chef.roles_path = "../my-recipes/roles"
	#   chef.data_bags_path = "../my-recipes/data_bags"
	#   chef.add_recipe "mysql"
	#   chef.add_role "web"
	#
	#   # You may also specify custom JSON attributes:
	#   chef.json = { :mysql_password => "foo" }
	# end

	# Enable provisioning with chef server, specifying the chef server URL,
	# and the path to the validation key (relative to this Vagrantfile).
	#
	# The Opscode Platform uses HTTPS. Substitute your organization for
	# ORGNAME in the URL and validation key.
	#
	# If you have your own Chef Server, use the appropriate URL, which may be
	# HTTP instead of HTTPS depending on your configuration. Also change the
	# validation key to validation.pem.
	#
	# config.vm.provision :chef_client do |chef|
	#   chef.chef_server_url = "https://api.opscode.com/organizations/ORGNAME"
	#   chef.validation_key_path = "ORGNAME-validator.pem"
	# end
	#
	# If you're using the Opscode platform, your validator client is
	# ORGNAME-validator, replacing ORGNAME with your organization name.
	#
	# IF you have your own Chef Server, the default validation client name is
	# chef-validator, unless you changed the configuration.
	#
	#   chef.validation_client_name = "ORGNAME-validator"


	Vagrant::Config.run do |config|

	  config.vm.provision :chef_solo do |chef|

	    http_proxy = ENV['http_proxy'] || ENV['HTTP_PROXY']

	    if !open("http://www.greensocs.com/") && !http_proxy
	      puts "Please set your http_proxy environment variable"
	      exit -1
	    end

	    chef.json = {:prefix => "/vagrant"}

	    chef.cookbooks_path = ["cookbooks", "."]

	    chef.http_proxy = http_proxy;
	    chef.https_proxy=http_proxy;
	    chef.add_recipe("chef-http_proxy");
	    chef.add_recipe("apt");
	    chef.add_recipe(@versions);

	    @cookbooks.each {|c| chef.add_recipe(c)};

	    chef.add_recipe(@toplevel);

	    chef.add_recipe("chef-autoshutdown");
	  end
	end

	config.ssh.forward_x11 = true

	config.vm.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/v-root", "1"]

	config.vm.customize ["modifyvm", :id, "--memory", @memory];

      end

    else
      
      pwd=File.dirname(File.dirname(File.expand_path(__FILE__)))
      Chef::Config[:file_cache_path]="/tmp/"
      Chef::Config[:cookbook_path]=["#{pwd}/cookbooks", "#{pwd}/"]
      Chef::Config[:json_attribs] = "/tmp/dna.json"
      File.open("/tmp/dna.json", mode='w') do |f|
	f.puts '{"run_list": ['
	@cookbooks.each {|c| f.puts "\"recipe[#{c}]\","}
	f.puts "\"recipe[#{@toplevel}]\""
	f.puts "],     \"prefix\":\"#{pwd}\"}"
      end
     
    end

  end
end
