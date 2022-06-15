MASTER_IP       = "192.168.56.10"
NODE_01_IP      = "192.168.56.20"
#VAGRANT_EXPERIMENTAL    = "cloud_init,disks"

Vagrant.configure("2") do |config|
  config.vagrant.plugins = %w(
    vagrant-hosts
    vagrant-hostmanager
  )
  
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = false
  config.hostmanager.manage_guest = true


  config.vm.box = "bento/ubuntu-22.04"
  config.vm.box_check_update = false
  config.ssh.username = "vagrant";
  config.ssh.password = "vagrant";
  config.ssh.insert_key = true;

  boxes = [
    { :name => "master01",  :ip => MASTER_IP,  :cpus => 2, :memory => 512 },
    { :name => "node01", :ip => NODE_01_IP, :cpus => 2, :memory => 512 },
  ]

  boxes.each do |opts|
    config.vm.define opts[:name] do |box|
      box.ssh.forward_agent = true
      box.vm.hostname = opts[:name]
      box.vm.network :private_network, ip: opts[:ip]
      box.vm.synced_folder ".", "/vagrant", type: "nfs", mount_options: ['actimeo=2'], nfs_udp: false
      box.vm.provider "virtualbox" do |vb|
        vb.cpus = opts[:cpus]
        vb.memory = opts[:memory]
    end
    box.vm.provision "shell", path:"./install-kubernetes-dependencies.sh"
      if box.vm.hostname.match(/master0[1-3]/) then 
        #box.vm.provision "shell", path:"./configure-master-node.sh"
        box.vm.provision "shell", inline: "echo Hello, master"
        end
      if box.vm.hostname.match(/node0[1-3]/) then
        #box.vm.provision "shell", path:"./configure-worker-nodes.sh"
        box.vm.provision "shell", inline: "echo Hello, worker"
        end
    end
  end
end