#
# 参考：https://dev.classmethod.jp/articles/terraform-lambda-deployment/
#      https://qiita.com/ktsujichan/items/c0804f155c2cf1962ed3
# 
# ソースの準備方法
#   1. build/resource_start/function/src 配下に python3.8 実行プログラム配置
#

data "archive_file" "function_zip2" {
  type        = "zip"
  source_dir  = "../../build/resource_start/function"
  output_path = "../../build/resource_start/function.zip"
}

# Function
resource "aws_lambda_function" "resource_start" {
  function_name = "${var.tags_owner}-${var.tags_env}-resource-start"

  handler          = "src/resource_start.lambda_handler"
  filename         = data.archive_file.function_zip2.output_path
  runtime          = "python3.8"
  publish          = true
  timeout          = 10
  role             = aws_iam_role.lambda.arn
  layers           = [aws_lambda_layer_version.resource_stop.arn]
  source_code_hash = filebase64sha256(data.archive_file.function_zip2.output_path)
  # ソースコードのハッシュ値で変更の有無を判断するため、日付は無視する
  lifecycle {
    ignore_changes = [
      last_modified
    ]
  }
  environment {
    variables = {
      tags_owner   = var.tags_owner
      tags_env     = var.tags_env
      ec2_win_name = aws_instance.ec2_win2019.tags.Name
      ec2_amzn_nam = aws_instance.ec2_amzn2.tags.Name
    }
  }

  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }

}

resource "aws_lambda_permission" "resource_start" {
  statement_id  = "${var.tags_owner}-${var.tags_env}-resource-start"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.resource_start.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.resource_start.arn
}
