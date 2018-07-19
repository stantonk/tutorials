# Terraform Tutorial


## Purpose

The goals of this tutorial are to learn Terraform basic concepts and apply it in a fully working example we'll try in AWS, by:

1. Install Terraform 0.11.7 using [tfenv](https://github.com/Zordrak/tfenv)
2. Introduce the basic Terraform concepts
3. Apply what you've learned by building a simple, isolated AWS Infrastructure in your own VPC, culminating in successfully sshing into an EC2 instance in that VPC from your laptop.

This tutorial assumes very little about the background of who is using it, I wanted to make it more generally accessible. Any improvements that can be made are greatly appreciated!


### Installing Terraform

I recommend installing terraform with `tfenv`, though installing `terraform` directly is fine too.

`brew install tfenv`

or

`brew install terraform`

Other things you'll need for this tutorial:

1. AWS access key id/secret to a **non-production AWS account**, with a [Default VPC](https://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/default-vpc.html) setup already for the Terraform Getting Started Guide tutorials to work.
2. Ideally console access to said non-production AWS account, as well as [AWS cli](https://aws.amazon.com/cli/) installed and configured for that account (`pip install awscli`)
3. [jq](https://stedolan.github.io/jq/), `brew install jq`

**NOTE**

*In the tutorials below we'll be spinning up real resources that cost real money, but they're simple and small enough and won't live long enough to be significant. The cost should be < $1 per person, I spent a few pennies going through Terraform's Getting Started as well as working on the end to end problem in Goal #3.*

### Terraform Basics

No reason to reinvent the wheel here, the [Terraform Getting Started Guide](https://www.terraform.io/intro/getting-started/install.html)
 docs are pretty great!

They'll lead you through some really basic examples and introduce you to most of the main concepts. You'll create and destroy some basic `resources` like EC2 instances, learn about `resource dependencies`, `provisioners`, `variables`, `modules`, etc.

I don't recommend actually running the `Remote Backends` tutorial, simply reading through it should be sufficient because there isn't much to be gained by spinning up a whole Consul cluster. Reading up on the concepts is definitely worth it.

As I mentioned above, these tutorials assume you've already got the [Default VPC](https://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/default-vpc.html) that comes with a brand new AWS account setup. The Default VPC creates a lot of the basic boilerplate that every sane AWS setup should have, so it makes the examples in the tutorials easier to play with. However, it glosses over some key concepts in the process that are fun to learn about and build *while using Terraform*, which is what the "homework" in part 3 is all about :).

### Apply what you've learned

Now it's time to do something a end-to-end in Terraform. We're going to build a "Default VPC" from scratch.

Requirements / Definition of Done:

* Addresses of the VPC are in `10.0.0.0/16`
* You have one public subnet inside your VPC of size `/20`
* You have a Security Group that only allows ingress SSH access on port 22, but Allow All for egress.
* Your infra is built in `us-east-1` as a default codified in your [IaC](https://en.wikipedia.org/wiki/Infrastructure_as_Code)
* You have 1 EC2 instance:
	* of type `t2-micro`
	* running `ubuntu 16.04 amd64, hvm:ebs-ssd` AMI
	* with a public IP address via an Elastic IP address
* You can run `terraform apply` and succcessfully SSH into an EC2 instance you provision inside your VPC by running the following two commands:

Apply your infrastructure as code to build everything in AWS:

```
$ TF_VAR_ssh_key_pub=`cat ~/.ssh/id_rsa.pub` terraform apply
```

SSH into the EC2 instance you created, by leveraging the aws cli and jq to extract the public IP address:

```
$ ssh ubuntu@`aws ec2 describe-instances | jq -r '.Reservations[].Instances[] | select(.State.Name != "terminated") | .PublicIpAddress'`
```

Recommended learning if you don't feel comfortable with concepts like VPC, Subnet, Gateway, CIDR, etc., go to [AWS Training](https://www.aws.training/) and watch the video "Subnets, Gateways, and Route Tables Explained".

Enjoy!