# For creating a local VM in which we can deploy and test recommender-tfidf.

Vagrant.configure(2) do |config|

	config.vm.hostname = "recommender-tfidf"
	config.vm.box = "amixsi/centos-7"  # includes VirtualBox Guest Additions
	config.vm.box_version = "1.0.0"
	config.vm.synced_folder "vm", "/vm", create: true
	config.vm.network "forwarded_port", guest: 8983, host: 8983  # needed to reach SOLR
	
	config.vm.provision "shell",
    	inline: "sudo yum install java-1.7.0-openjdk"  # needed for SOLR
    
	config.vm.provision "shell",
		inline: "sudo yum install net-tools"  # basic tools such as ifconfig

end
