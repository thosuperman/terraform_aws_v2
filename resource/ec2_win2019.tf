# search ami
# https://dev.classmethod.jp/articles/launch-ec2-from-latest-ami-by-terraform/
data "aws_ami" "win2019_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "name"
    values = ["Windows_Server-2019-Japanese-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "block-device-mapping.volume-type"
    values = ["gp2"]
  }
}

# EC2
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
resource "aws_instance" "ec2_win2019" {
  ami           = data.aws_ami.win2019_ami.id
  instance_type = "t3.2xlarge"
  key_name      = aws_key_pair.key_pair.key_name
  vpc_security_group_ids = [
    aws_security_group.ec2.id
  ]
  subnet_id = aws_subnet.ec2["eu-north-1a"].id
  root_block_device {
    volume_type = "gp2"
    volume_size = "30"
  }
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2.name

  # 下記の項目が変更されると強制的にリソースの再作成が行われてしまうのでそれを防ぐ。
  # ・ami は一定期間で最新版にアップデートされる。
  # ・associate_public_ip_address はインスタンスがシャットダウンすると false に変更される。
  lifecycle {
    ignore_changes = [
      ami,
      associate_public_ip_address,
      user_data
    ]
  }

  # 初期設定
  user_data = <<EOF
  <powershell>
  # オリジナル管理ユーザー作成
  New-LocalUser -Name ${var.tags_owner} -Password (ConvertTo-SecureString "${var.db_master_password.windows2019}" -AsPlainText -Force) -PasswordNeverExpires
  Add-LocalGroupMember -Group Administrators -Member ${var.tags_owner}
  
  # S3（s3://aws-aqua-terraform/koizumi/windows）より各種アプリダウンロード
  New-Item "C:\applications" -ItemType "directory"
  Read-S3Object -BucketName aws-aqua-terraform -Prefix koizumi/windows -Folder "C:\applications"
  
  # 日本時間
  Set-TimeZone -Id "Tokyo Standard Time"
  
  # 日本語キーボード設定
  Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\KeyboardType Mapping\JPN' -Name 00000000 -Value kbd106.dll
  Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\KeyboardType Mapping\JPN' -Name 00010002 -Value kbd106.dll
  </powershell>
  EOF

  tags = {
    Name  = "${var.tags_owner}-${var.tags_env}-win2019"
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}