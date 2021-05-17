# packer-terraform-network-firewall-demo

Packer/Teraformを使ったALB+Auto Scaling構成にAWS Network Firewallを追加したデモです。

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
$ terraform init
$ terraform plan
$ terraform apply
```

- ALBのDNS名でアクセスしてWebサーバが見えればOK。あとはNetwork Firewallをいろいろいじってみてください。
- EC2インスタンスはSession Managerを有効にしてあるので、SSHは不要で、マネジメントコンソールからログイン可能。

削除

```
$ terraform destroy
```

AMIやスナップショットも不要なら削除
