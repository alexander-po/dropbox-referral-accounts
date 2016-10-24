# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
    config.vm.box = "archlinux-dropbox.box"

    config.vm.synced_folder ".", "/vagrant", type: "nfs"
    config.vm.network :private_network, type: "dhcp"

    config.vm.provider "virtualbox" do |virtualbox|
        virtualbox.customize ["modifyvm", :id, "--macaddress1", ENV['MAC_ADDRESS'] ]
    end
    
    config.vm.provision "shell" do |s|
        s.path = "scripts/manage-account.sh"
        s.privileged = false
        s.args = ["#{ENV['FIRST']}", "#{ENV['LAST']}", "#{ENV['EMAIL']}"]
    end

end
