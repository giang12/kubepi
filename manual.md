1. Flash fresh vanilla Raspbian image to sd 
	dont forget to `touch ssh` in /boot/ on the SD card

2. ./prep.sh {id} {hostname} {address}

	```shell
	./prep.sh 0 kubeleader 192.168.0.3
	./prep.sh 1 kubepi-1 192.168.0.8
	./prep.sh 2 kubepi-2 192.168.0.12
	...etc
	```
3. Install
	```shell
	./rpc/_install_docker.sh $USER 192.168.0.100
	./rpc/_install_kube.sh $USER 192.168.0.100
	```
4. Set up containers networking, storage, and monitoring dashboards
 ./login.sh $address
 kubectl apply -f manifests/flannel.yml
