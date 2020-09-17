output "out-sg-mongo_id"{
    value ="${aws_security_group.sg-mongo.id}"
}

output "out-mongo-ec2-subnet-private_ids" {
  	value = ["${aws_subnet.mongo-subnet-private.*.id}"]
}

output "out-bastion-public-ip" {
	value = ["${aws_eip.eip-bastion.*.public_ip}"]
}
