# Create zip file of all lambda functions
data "archive_file" "connect_handler_zipped_file" {
  type        = "zip"
  source_file = "${path.module}/functions/connect.js"
  output_path = "${path.module}/zipped-functions/connect.zip"
}

data "archive_file" "disconnect_handler_zipped_file" {
  type        = "zip"
  source_file = "${path.module}/functions/disconnect.js"
  output_path = "${path.module}/zipped-functions/disconnect.zip"
}

data "archive_file" "sendmessage_handler_zipped_file" {
  type        = "zip"
  source_file = "${path.module}/functions/sendMessage_handler.js"
  output_path = "${path.module}/zipped-functions/sendMessage_handler.zip"
}

# Create policy document for lambda
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

data "aws_iam_policy_document" "connect_disconnect_handler_policy_document" {
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

data "aws_iam_policy_document" "message_handler_policy_document" {
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

# Create Policy for lambda
resource "aws_iam_policy" "message_handler_policy" {
  policy = data.aws_iam_policy_document.message_handler_policy_document.json
  name   = "message_handler_policy"
}

resource "aws_iam_policy" "connect_disconnect_handler_policy" {
  policy = data.aws_iam_policy_document.connect_disconnect_handler_policy_document.json
  name   = "connect_disconnect_handler_policy"
}

# Create role for lambda
resource "aws_iam_role" "connect_disconnect_role_handler" {
  assume_role_policy = data.aws_iam_policy_document.assume_policy_document.json
  name               = "connect_disconnect_role_handler"
}

resource "aws_iam_role" "message_role_handler" {
  assume_role_policy = data.aws_iam_policy_document.assume_policy_document.json
  name               = "message_role_handler"
}

# Create role attachment with policy in lambda
resource "aws_iam_role_policy_attachment" "lambda_execution_policy_attachment" {
  for_each = toset([
    aws_iam_role.connect_disconnect_role_handler.name,
    aws_iam_role.message_role_handler.name,
  ])
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = each.value
}

resource "aws_iam_role_policy_attachment" "connect_lambda_handler" {
  role       = aws_iam_role.connect_disconnect_role_handler.name
  policy_arn = aws_iam_policy.connect_disconnect_handler_policy.arn
}

# Create connect lambda
resource "aws_lambda_function" "connect_handler" {
  filename         = data.archive_file.connect_handler_zipped_file.output_path
  function_name    = "connect_handler"
  role             = aws_iam_role.connect_disconnect_role_handler.arn
  handler          = "connect.handler"
  source_code_hash = data.archive_file.connect_handler_zipped_file.output_base64sha256

  runtime = "nodejs24.x"

  environment {
    variables = {
      ENVIRONMENT = var.env
      TABLE_NAME  = var.dynamodb_name
    }
  }

  tags = {
    Environment = var.env
  }

  depends_on = [aws_iam_role.connect_disconnect_role_handler, data.archive_file.connect_handler_zipped_file]
}

# Create disconnect lambda
resource "aws_lambda_function" "disconnect_handler" {
  filename         = data.archive_file.disconnect_handler_zipped_file.output_path
  function_name    = "disconnect_handler"
  role             = aws_iam_role.connect_disconnect_role_handler.arn
  handler          = "disconnect.handler"
  source_code_hash = data.archive_file.disconnect_handler_zipped_file.output_base64sha256

  runtime = "nodejs24.x"

  environment {
    variables = {
      ENVIRONMENT = var.env
      TABLE_NAME  = var.dynamodb_name
    }
  }

  tags = {
    Environment = var.env
  }

  depends_on = [aws_iam_role.connect_disconnect_role_handler, data.archive_file.disconnect_handler_zipped_file]
}

# Create message lambda
resource "aws_lambda_function" "sendmessage_handler" {
  filename         = data.archive_file.sendmessage_handler_zipped_file.output_path
  function_name    = "sendmessage_handler"
  role             = aws_iam_role.message_role_handler.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.sendmessage_handler_zipped_file.output_base64sha256

  runtime = "nodejs24.x"

  environment {
    variables = {
      ENVIRONMENT = var.env
      TABLE_NAME  = var.dynamodb_name
    }
  }

  tags = {
    Environment = var.env
  }

  depends_on = [aws_iam_role.message_role_handler, data.archive_file.sendmessage_handler_zipped_file]
}
