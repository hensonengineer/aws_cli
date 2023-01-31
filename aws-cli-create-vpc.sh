
## CREATE THE VPC ##
#aws ec2 create-vpc --cidr-block CIDR_BLOCK
# these next two do the same thing, expect saving the output as a varible. 
#$ VPC_OUTPUT=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16)
$ VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query 'Vpc.VpcId' --output text)
# ensure DNS support is on
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames
# create tags
aws ec2 create-tags --resource $VPC_ID --tags Key=Name,Value=CLI_DEMO_VPC

## CREATE SUBNETS E ##
#aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24
#aws ec2 create-subnet --vpc-id vpc-0123456789abcdef0 --cidr-block 10.0.1.0/24 --availability-zone us-west-2a
#aws ec2 create-subnet --vpc-id vpc-0123456789abcdef0 --cidr-block 10.0.1.0/24 --cidr-block 10.0.2.0/24 --availability-zone us-west-2a --availability-zone us-west-2b
#aws ec2 create-subnet --vpc-id vpc-0123456789abcdef0 --cidr-block 10.0.1.0/24
# these next two do the same thing, expect saving the output as a varible. 
PUBLIC_SUBNET1_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 --availability-zone us-west-2a --query 'Subnet.SubnetId' --output text)
PUBLIC_SUBNET2_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.3.0/24 --availability-zone us-west-2b --query 'Subnet.SubnetId' --output text)
PRIVATE_SUBNET1_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.2.0/24 --availability-zone us-west-2a --query 'Subnet.SubnetId' --output text)
PRIVATE_SUBNET2_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.4.0/24 --availability-zone us-west-2b --query 'Subnet.SubnetId' --output text)
#create tags
aws ec2 create-tags --resource $PUBLIC_SUBNET1_ID --tags Key=Name,Value=PUBLIC_SUBNET1_ID
aws ec2 create-tags --resource $PUBLIC_SUBNET2_ID --tags Key=Name,Value=PUBLIC_SUBNET2_ID
aws ec2 create-tags --resource $PRIVATE_SUBNET1_ID --tags Key=Name,Value=PRIVATE_SUBNET1_ID
aws ec2 create-tags --resource $PRIVATE_SUBNET2_ID --tags Key=Name,Value=PRIVATE_SUBNET2_ID

## CREATE THE ROUTE TABLES ##

aws ec2 create-route-table --vpc-id $VPC_ID
# these next two do the same thing, expect saving the output as a varible. 
# ROUTE_TABLE=$(aws ec2 create-route-table --vpc-id $VPC_ID)
PUBLIC_ROUTE_TABLE_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)
PRIVATE_ROUTE_TABLE_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)
# create tags
aws ec2 create-tags --resource $PUBLIC_ROUTE_TABLE_ID --tags Key=Name,Value=PUBLIC_ROUTE_TABLE
aws ec2 create-tags --resource $PRIVATE_ROUTE_TABLE_ID --tags Key=Name,Value=PRIVATE_ROUTE_TABLE

## ASSOCIATE SUBNETS TO ROUTE TABLES ##
# aws ec2 associate-route-table --route-table-id rtb-01234567890abcdef0 --subnet-id subnet-01234567890abcdef0
#This will create a new internet gateway and return its InternetGatewayId in the output. You can save the ID to a variable
# aws ec2 create-internet-gateway
# the next one does the same thing, expect saving the output as a varible.
GATEWAY_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)

## ATTACH INTERNET GATEWAY ##
aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $GATEWAY_ID

## ADD A ROUTE FOR THE INTERNET FR PUBLIC SUBNETS##
# aws ec2 create-route --route-table-id rtb-12345678 --destination-cidr-block 10.0.0.0/16 --gateway-id igw-abcdefgh
aws ec2 create-route --route-table-id $PUBLIC_ROUTE_TABLE_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $GATEWAY_ID

## CREATE NAT GATEWAY ##
# allocate EIP
ALLOCATION_ID=$(aws ec2 allocate-address --domain vpc --output text --query 'AllocationId')
echo "Allocation ID: $ALLOCATION_ID"

#aws ec2 create-nat-gateway --subnet-id $PUBLIC_SUBNET1_ID --allocation-id $ALLOCATION_ID
# the next one does the same thing, expect saving the output as a varible.
NAT_GATEWAY_ID=$(aws ec2 create-nat-gateway \
  --subnet-id $PUBLIC_SUBNET1_ID \
  --allocation-id $ALLOCATION_ID \
  --query 'NatGateway.NatGatewayId' \
  --output text)


## ADD A ROUTE FOR THE INTERNET FR PUBLIC SUBNETS##
# aws ec2 create-route --route-table-id rtb-12345678 --destination-cidr-block 10.0.0.0/16 --gateway-id igw-abcdefgh
aws ec2 create-route --route-table-id $PRIVATE_ROUTE_TABLE_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $NAT_GATEWAY_ID



