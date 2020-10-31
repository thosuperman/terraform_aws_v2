# terraform_aws_v2
terraform apply とコマンド実行するだけで AWS の各リソース（vpc/subnet/s3/ec2/rds/...etc）を自動的に構築することが可能です。現在は以下のバージョンに対応しています。
| key       | value                     |
| --------- | ------------------------- |
| terraform | 0.13.5                    |
| aws       | 3.12.0                    |
| region    | eu-north-1（ストックホルム） |

# 利用タグ一覧
利用タグ（Owner/Env）の組み合わせ毎にサブネットを割り当てています。<br>
| No | Owner    | Env | subnet id |
| -- | -------- | --- | --------- |
| 1  | koizumi  | dev | 10 - 19   |
| 2  | koizumi  | stg | 20 - 29   |
| 3  | koizumi  | prd | 30 - 39   |

# はじめにやっておくこと
コマンド実行前に、以下のことが必要です。
1. terraform.exe を取得

    下記URL より terraform.exe をダウンロード<br>
    https://www.terraform.io/downloads.html<br>
    ※ Windows であれば、terraform.exe をダウンロードして PATH を通すだけです。

2. terraform.exe へ PATH を通す。

    PATH の通し方がわからない場合は、以下のURL等を参考にしてください。<br>
    https://qiita.com/miwato/items/b7e66cb087666c3f9583<br>
    https://dev.classmethod.jp/articles/try-terraform-on-windows/<br>
    https://proengineer.internous.co.jp/content/columnfeature/5205

3. credentials 作成

    空のファイル C:¥user¥.aws¥credentials を作成してください。

4. AWS アクセスキー情報登録

    credentials に以下の内容を入力してください。<br>
    profile 名は自身のものに置き換えてください。
    ```
    [koizumi]
    aws_access_key_id = "xxxxxxxxxxxxxxxxxxxx"
    aws_secret_access_key = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    ```

5. s3 バケット作成

    terraform は .tfstate というファイルでリソースの状態を保持します。<br>
    セキュリティや運用の観点からローカルに保存するのではなく、s3 に置くことが推奨されています。<br>
    事前に保管用の s3 を用意してください。

以下、module の説明を記載します。

# module vpc
vpc を管理する module です。この module は変更しないでください。<br>
全環境で vpc は共有しています。

# module resource
AWS の各リソースを管理する module です。<br>
他環境のリソースを操作できないよう、タグ名（owner_tag,tags_env）を利用しています。<br>
iam はタグ名（owner_tag,tags_env）から始まるリソースに対してのみ操作できるよう設定しています。
