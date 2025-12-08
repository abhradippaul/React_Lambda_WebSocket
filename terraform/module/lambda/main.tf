data "archive_file" "connect_handler_zipped_file" {
  type        = "zip"
  source_file = "${path.module}/functions/connect_handler.js"
  output_path = "${path.module}/zipped-functions/connect_handler.zip"
}

data "archive_file" "disconnect_handler_zipped_file" {
  type        = "zip"
  source_file = "${path.module}/functions/disconnect_handler.js"
  output_path = "${path.module}/zipped-functions/disconnect_handler.zip"
}

data "archive_file" "sendmessage_handler_zipped_file" {
  type        = "zip"
  source_file = "${path.module}/functions/sendMessage_handler.js"
  output_path = "${path.module}/zipped-functions/sendMessage_handler.zip"
}

data "aws_iam_policy_document" "assume_policy_document" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
    ]
  }
}

data "aws_iam_policy_document" "dynamodb_handler_policy_document" {
  statement {
    actions = [
      "dynamodb:BatchWriteItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:DescribeTable"
    ]
    resources = [var.dynamodb_arn]
  }
}

data "aws_iam_policy_document" "sendmessage_handler_policy_document" {
  statement {
    actions = [
      "dynamodb:BatchGetItem",
      "dynamodb:GetRecords",
      "dynamodb:GetShardIterator",
      "dynamodb:Query",
      "dynamodb:GetItem",
      "dynamodb:Scan",
      "dynamodb:ConditionCheckItem",
      "dynamodb:DescribeTable"

    ]
    resources = [var.dynamodb_arn]
  }
}

resource "aws_iam_policy" "dynamodb_handler_policy" {
  policy = data.aws_iam_policy_document.dynamodb_handler_policy_document.json
  name   = "dynamodb_handler_policy"
}

resource "aws_iam_role" "role_handler" {
  assume_role_policy = data.aws_iam_policy_document.assume_policy_document.json
  name               = "role_handler"
}

resource "aws_iam_role_policy_attachment" "role_handler" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.role_handler.name
}

resource "aws_iam_role_policy_attachment" "dynamodb_connect_handler" {
  role       = aws_iam_role.role_handler.name
  policy_arn = aws_iam_policy.dynamodb_handler_policy.arn
}

resource "aws_lambda_function" "connect_handler" {
  filename         = data.archive_file.connect_handler_zipped_file.output_path
  function_name    = "connect_handler"
  role             = aws_iam_role.role_handler.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.connect_handler_zipped_file.output_base64sha256

  runtime = "nodejs22.x"

  environment {
    variables = {
      ENVIRONMENT = var.env
      TABLE_NAME  = var.dynamodb_name
    }
  }

  tags = {
    Environment = var.env
  }

  depends_on = [aws_iam_role.role_handler, data.archive_file.connect_handler_zipped_file]
}

resource "aws_lambda_function" "disconnect_handler" {
  filename         = data.archive_file.disconnect_handler_zipped_file.output_path
  function_name    = "disconnect_handler"
  role             = aws_iam_role.role_handler.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.disconnect_handler_zipped_file.output_base64sha256

  runtime = "nodejs22.x"

  environment {
    variables = {
      ENVIRONMENT = var.env
      TABLE_NAME  = var.dynamodb_name
    }
  }

  tags = {
    Environment = var.env
  }

  depends_on = [aws_iam_role.role_handler, data.archive_file.disconnect_handler_zipped_file]
}

resource "aws_lambda_function" "sendmessage_handler" {
  filename         = data.archive_file.sendmessage_handler_zipped_file.output_path
  function_name    = "sendmessage_handler"
  role             = aws_iam_role.role_handler.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.sendmessage_handler_zipped_file.output_base64sha256

  runtime = "nodejs22.x"

  environment {
    variables = {
      ENVIRONMENT = var.env
      TABLE_NAME  = var.dynamodb_name
    }
  }

  tags = {
    Environment = var.env
  }

  depends_on = [aws_iam_role.role_handler, data.archive_file.sendmessage_handler_zipped_file]
}
