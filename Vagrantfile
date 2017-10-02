Vagrant.configure(2) do |config|

	config.vm.hostname = "recommender-tfidf"
	config.vm.box = "amixsi/centos-7"
	config.vm.box_version = "1.0.0"
	config.vm.synced_folder "vm", "/vm", create: true
	config.vm.network "forwarded_port", guest: 8983, host: 8983
	
	config.vm.provision "shell",
    	inline: "sudo yum install java-1.7.0-openjdk"
    
	config.vm.provision "shell",
		inline: "sudo yum install net-tools"

end
