 output "eks_cluster_endpoint" {
   value = aws_eks_cluster.html_db_cluster.endpoint
 }

 output "vpc_id" {
   value = aws_vpc.html_db_vpc.id
 }

 output "public_subnet_id_1" {
   value = aws_subnet.html_db_public_subnet_1.id
 }

 output "public_subnet_id_2" {
   value = aws_subnet.html_db_public_subnet_2.id
 }

 output "private_subnet_id_1" {
   value = aws_subnet.html_db_private_subnet_1.id
 }

 output "private_subnet_id_2" {
   value = aws_subnet.html_db_private_subnet_2.id
 }
