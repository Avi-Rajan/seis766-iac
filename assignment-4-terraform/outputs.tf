output "web1_public_ip" {
  description = "Public IP of the first web server"
  value       = aws_instance.web1.public_ip
}

output "web2_public_ip" {
  description = "Public IP of the second web server"
  value       = aws_instance.web2.public_ip
}

output "rds_endpoint" {
  description = "Endpoint of the RDS MySQL instance"
  value       = aws_db_instance.mysql.endpoint
}
