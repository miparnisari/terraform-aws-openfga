# terraform-aws

> Not production ready!

This is a Terraform module to deploy OpenFGA in AWS ECS with either a Postgres storage (default) or an in-memory storage. We are using it for benchmarking purposes for the moment.

The module will create a VPC, three OpenFGA instances, and a load balancer. If backed by Postgres, it will also create a Postgres cluster and run the database migrations.

The outputs of this module are `name` of the ECS cluster and the `endpoint` of the load balancer to reach OpenFGA.