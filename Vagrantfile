# For creating a local VM in which we can deploy and test recommender-tfidf.

Vagrant.configure(2) do |config|

	config.vm.hostname = "recommender-tfidf"
	config.vm.box = "amixsi/centos-7"  # includes VirtualBox Guest Additions
	config.vm.box_version = "1.0.0"
	config.vm.network "forwarded_port", guest: 3306, host: 3306
	
	# Synced folders: the host directory containing this Vagrantfile is automatically
	# mapped to the VM folder /vagrant.
	
	# Networking.
	config.vm.network "forwarded_port", guest: 8983, host: 8983  # needed to reach SOLR
	
	# Software provisioning.
	config.vm.provision "shell",
    	inline: "sudo yum install -y java-1.7.0-openjdk"  # needed for SOLR
    
	config.vm.provision "shell",
		inline: "sudo yum install -y net-tools"  # basic tools such as ifconfig
	
	config.vm.provision "shell",
		inline: "sudo yum remove docker docker-common docker-selinux docker-engine"
	
	config.vm.provision "shell",
		inline: "sudo yum install -y yum-utils device-mapper-persistent-data lvm2"
	
	config.vm.provision "shell",
		inline: "sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo"
	
	config.vm.provision "shell",
		inline: "sudo yum install -y docker-ce"
	
	config.vm.provision "shell",
		inline: "sudo systemctl start docker"
		
	config.vm.provision "shell",
		inline: "sudo curl -L https://github.com/docker/compose/releases/download/1.16.1/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose"
	
	config.vm.provision "shell",
		inline: "sudo chmod +x /usr/local/bin/docker-compose"

end
