# Terraform Playground

Dockerized Terraform playground that minimizes installed dependencies. 

Dependencies:
- Docker
- GNU Make (not required but makes things easier)

To build/run the Terraform container:

`make`

If you need to rebuild the container, run `docker-compose build` or `docker-compose up --build`.

# Deploying the Terraform backend

```shell
cd tf-backend
# modify bucket and ddb table name as needed...
terraform init
terraform apply
```
# Deploying the web server ASG configuration

Define an AWS profile in `~/.aws`, then use it to deploy.

```shell
make
AWS_PROFILE=myprofile
terraform init
```

There are two variables: `server_port` and `ingress_address`. The default server port is 8080. You have to define your source IP address to access the server (you can do that with `curl ifconfig.co`)

You can define the variables any way you want -- a `TF_VAR_` environment variable, the `-var` option, or a `tfvars` file.

Then run `terraform plan` and `terraform apply`.