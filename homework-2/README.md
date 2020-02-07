# ДЗ №2. Дисковая подсистема
[ ] Создать скрипт для создания рейда, конф для автосборки рейда при загрузке
[ ]* Vagrantfile, который сразу собирает систему с подключенным рейдом
[ ]** перенесети работающую систему с одним диском на RAID 1. Даунтайм на загрузку с нового диска предполагается. В качестве проверики принимается вывод команды lsblk до и после и описание хода решения (можно воспользовать утилитой Script). 
---

## Основное задание. Собрать RAID.

### В процессе работы сделано

 [x] Добавить в Vagrantfile еще дисков.
 [ ] Собрать raid

#### Добавление дисков в Vagrantfile.

За основу возьму Vagrantfile из первого домашнего задания и добавлю в него опции строки из [Vagrantfile от Алексея Цикунова, который есть в материалах второго урока](https://github.com/erlong15/otus-linux/blob/master/Vagrantfile) . Добавились следующие строки.

1. В первой секции. Добавил 4 диска, указал папку, размер и порт котроллера через соответствующие переменные.

```
	#disks
		:disks => {
		:sata1 => {
			:dfile => './sata1.vdi',
			:size => 250,
			:port => 1
		},
		:sata2 => {
                        :dfile => './sata2.vdi',
                        :size => 250, # Megabytes
			:port => 2
		},
                :sata3 => {
                        :dfile => './sata3.vdi',
                        :size => 250,
                        :port => 3
                },
                :sata4 => {
                        :dfile => './sata4.vdi',
                        :size => 250, # Megabytes
                        :port => 4
                }

	},

```
2. Во второй секции внутри конструкции *box.vm.provider "virtualbox" do |vb|*, в которой указываются парметры виртуальной машины провайдера VirtualBox о которых подробнее можно почитать в [мануале](https://www.virtualbox.org/manual/ch08.html#vboxmanage-storagectl)
В ruby и программировании я не силен, но в целом тут с помощью команд createhd, storageattach, storagectl и переменных из первой секции создаются контроллер и диски.

```
	# Set VM disks and controller
	needsController = false
		  boxconfig[:disks].each do |dname, dconf|
			  unless File.exist?(dconf[:dfile])
				vb.customize ['createhd', '--filename', dconf[:dfile], '--variant', 'Fixed', '--size', dconf[:size]]
                                needsController =  true
                          end

		  end
                  if needsController == true
                     vb.customize ["storagectl", :id, "--name", "SATA", "--add", "sata" ]
                     boxconfig[:disks].each do |dname, dconf|
                         vb.customize ['storageattach', :id,  '--storagectl', 'SATA', '--port', dconf[:port], '--device', 0, '--type', 'hdd', '--medium', dconf[:dfile]]
                     end
                  end
	
      end

```

Полный Vagrantfile выложен в репозитории. Идем дальше.

---

#### Собрать raid.





