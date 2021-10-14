resource "local_file" "ansible_host" {
  depends_on = [
    aws_instance.k8s-master,
    aws_instance.k8s-workers
  ]
#   count    = 4
  content  = "[Master_Node]\n${aws_instance.k8s-master.public_ip}\n\n[Worker_Node]\n${join("\n", aws_instance.k8s-workers.*.public_ip)}"
  filename = "../ansible/inventory"
}

resource "null_resource" "run_ansible" {
    depends_on = [
      local_file.ansible_host
    ]
  provisioner "local-exec" {
    command = "sleep 30"
    }
  provisioner "local-exec" {
    command = "ansible-playbook -i ../ansible/inventory ../ansible/playbook.yml --key-file ~/.ssh/ida_rsa "

    }
}