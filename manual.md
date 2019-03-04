1. Flash vanilla Raspbian image to sd 
	dont forget to `touch ssh` in /boot/ on the SD card

2. ./prep.sh {id} {hostname} {address}

	```shell
	./prep.sh 0 kubeleader 192.168.0.3
	./prep.sh 1 kubepi-1 192.168.0.8
	./prep.sh 2 kubepi-2 192.168.0.12
	...etc
	```
3. Install
	docker
	kubeadm kubectl 
	
