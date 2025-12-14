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
  source_file = "${path.module}/functions/sendMessage.js"
  output_path = "${path.module}/zipped-functions/sendMessage.zip"
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

data "aws_iam_policy_document" "lambda_handler_policy_document" {
  statement {
    actions = [
      "dynamodb:BatchWriteItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:DescribeTable",
      "dynamodb:BatchDeleteItem",
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

data "aws_iam_policy_document" "apigateway_policy_document" {
  statement {
    effect = "Allow"

    actions = [
      "execute-api:ManageConnections"
    ]

    resources = [
      "arn:aws:execute-api:ap-south-1:739275445912:${var.apigateway_id}/production/POST/@connections/*"
    ]
  }
}


# data "aws_caller_identity" "current" {

# }

# data "aws_iam_policy_document" "execute_api_message_handler_policy_document" {
#   statement {
#     actions = [
#       "execute-api:ManageConnections"
#     ]
#     resources = ["arn:aws:execute-api:ap-south-1:${data.aws_caller_identity.current.account_id}:pbssx5s6je/production/POST/@connections/*"]
#   }
# }

# Create Policy for lambda
resource "aws_iam_policy" "lambda_handler_policy" {
  policy = data.aws_iam_policy_document.lambda_handler_policy_document.json
  name   = "lambda_handler_policy"
}

resource "aws_iam_policy" "execute_api_message_handler_policy" {
  policy = data.aws_iam_policy_document.apigateway_policy_document.json
  name   = "execute_api_message_handler_policy"
}

# Create role for lambda
resource "aws_iam_role" "lambda_role_handler" {
  assume_role_policy = data.aws_iam_policy_document.assume_policy_document.json
  name               = "lambda_role_handler"
}

# Create role attachment with policy in lambda
resource "aws_iam_role_policy_attachment" "lambda_execution_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role_handler.name
}

resource "aws_iam_role_policy_attachment" "lambda_handler_attachment" {
  role       = aws_iam_role.lambda_role_handler.name
  policy_arn = aws_iam_policy.lambda_handler_policy.arn
}

resource "aws_iam_role_policy_attachment" "execute_api_message_lambda_handler" {
  role       = aws_iam_role.lambda_role_handler.name
  policy_arn = aws_iam_policy.execute_api_message_handler_policy.arn
}

# Create connect lambda
resource "aws_lambda_function" "connect_handler" {
  filename         = data.archive_file.connect_handler_zipped_file.output_path
  function_name    = "connect_handler"
  role             = aws_iam_role.lambda_role_handler.arn
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

  depends_on = [aws_iam_role.lambda_role_handler, data.archive_file.connect_handler_zipped_file]
}

# Create disconnect lambda
resource "aws_lambda_function" "disconnect_handler" {
  filename         = data.archive_file.disconnect_handler_zipped_file.output_path
  function_name    = "disconnect_handler"
  role             = aws_iam_role.lambda_role_handler.arn
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

  depends_on = [aws_iam_role.lambda_role_handler, data.archive_file.disconnect_handler_zipped_file]
}

# Create message lambda
resource "aws_lambda_function" "sendmessage_handler" {
  filename         = data.archive_file.sendmessage_handler_zipped_file.output_path
  function_name    = "sendmessage_handler"
  role             = aws_iam_role.lambda_role_handler.arn
  handler          = "sendMessage.handler"
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

  depends_on = [aws_iam_role.lambda_role_handler, data.archive_file.sendmessage_handler_zipped_file]
}
