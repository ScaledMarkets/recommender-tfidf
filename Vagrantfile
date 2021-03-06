# For creating a local VM in which we can deploy and test recommender-tfidf
# as a container. This is necessary because the mysql container image does not
# seem to work in OS-X Docker.

Vagrant.configure(2) do |config|

	config.vm.hostname = "recommender-tfidf"
	
	# OS.
	config.vm.box = "amixsi/centos-7"  # includes VirtualBox Guest Additions
	config.vm.box_version = "1.0.0"
	
	# Synced folders.
	# Note: the host directory containing this Vagrantfile is automatically mapped
	# to the VM folder /vagrant.
	config.vm.synced_folder "~/Transient/tfidf", "/Transient", create: true
	
	# Networking.
	config.vm.network "forwarded_port", guest: 8080, host: 8080
	config.vm.network "forwarded_port", guest: 3306, host: 3306
	
	# Software provisioning.
	
	# JDK
	# See http://openjdk.java.net/install/
	# See http://jdk.java.net/10/
	# See http://jdk.java.net/java-se-ri/9
	config.vm.provision "shell",
    	inline: "curl https://download.java.net/openjdk/jdk9/ri/openjdk-9+181_linux-x64_ri.zip -o openjdk-9+181_linux-x64_ri.zip"
	
    config.vm.provision "shell",
    	inline: "unzip openjdk-9+181_linux-x64_ri.zip"
    
	config.vm.provision "shell",
    	inline: "sudo yum install -y java-1.8.0-openjdk-devel"
    
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
	
	config.vm.provision "shell",
		inline: "sudo yum install -y maven"
	
	config.vm.provision "shell",
		inline: "sudo usermod -aG docker vagrant"

end
