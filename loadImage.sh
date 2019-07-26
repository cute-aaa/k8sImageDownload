#!/bin/bash

chmod 777 images.tar
tar -xzvf images.tar

cd images/
tars=($(ls *.tar */*.tar */*/*.tar))

for i in ${tars[@]}
do
	docker load -i $i
done