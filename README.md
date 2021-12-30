# Terraform Script 
* ## Prod.tf creates:
1. #### S3 Bucket 
2. #### Lanch template that creates an Nginx instance
3. #### Default VPC, and two different subnets in us-west-2 for the ELB
4. #### Security group with two rules the ports are 80 & 443 with tcp protocol and cidr block that allows everything in for both rules 
      ###### *It's not a best practice It's only for learning*
5. #### Elastic load balancer configured with the pre made subnets and ASG.
6. #### Autoscaling group configured with desired capacity, min size, max size of instances which are configured in the variables file and the pre made availability zones
7. #### An auto scaling attachement to connect the ELB to the ASG
8. #### Each of these resourses are created with a Terraform tag, because it's a best practice to identify which resources are managed by terraform 
* ## Terraform.tfvars is where all the variables are created to delete hard coded values in prod.tf
