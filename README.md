# packer-terraform-network-firewall-demo

Packer/Teraformを使ったNLB+Auto Scaling構成にAWS Network Firewallを追加したデモです。

## Usage

レポジトリをクローン

```
$ git clone https://github.com/kun432/packer-terraform-network-firewall-demo.git
$ cd packer-terraform-network-firewall-demo
```

PackerでAMIを作る。AMI IDを控えておく。

```
$ cd packer
$ packer build .
$ cd ..
```

TerraformでAWSリソースを作成

```
$ cd terraform
$ cd envs/development
```

- VPC CIDRなど、カスタマイズする場合はvariables.tfを修正してください。
- tfstateはS3に保存します。S3バケット名はbackend.tfを修正してください。

適用

```
$ terraform init
$ terraform plan
$ terraform apply
```

- ホワイトリストからのアクセスのみを許可するIPSルールを入れてあります。variables.tfのhttp_permit_ipsに自分のIPアドレスを指定すればアクセス可能です。
- EC2インスタンスはSession Managerを有効にしてあるので、SSHは不要で、マネジメントコンソールからログイン可能。

削除

```
$ terraform destroy
```

AMIやスナップショットも不要なら削除
