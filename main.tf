
data "archive_file" "ws_messenger_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/messenger/main.py"
  output_path = "${path.module}/tmp/messenger.zip"
}

data "archive_file" "ws_authorizer_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/authorizer/main.py"
  output_path = "${path.module}/tmp/authorizer.zip"
}

data "archive_file" "ws_connect_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/connect/main.py"
  output_path = "${path.module}/tmp/connect.zip"
}

data "archive_file" "ws_disconnect_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/disconnect/main.py"
  output_path = "${path.module}/tmp/disconnect.zip"
}

data "aws_iam_policy_document" "ws_lambda_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect    = "Allow"
    resources = ["arn:aws:logs:*:*:*"]
  }
  statement {
    actions = [
      "dynamodb:BatchWriteItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:DescribeTable"
    ]
    effect    = "Allow"
    resources = [aws_dynamodb_table.ws_messenger_table.arn]
  }
}

data "aws_iam_policy_document" "ws_lambda_messenger_policy" {
  statement {
    actions = [
      "dynamodb:Scan"
    ]
    effect    = "Allow"
    resources = [aws_dynamodb_table.ws_messenger_table.arn]
  }
}

data "aws_iam_policy" "apigw_invoke_access" {
  name = "AmazonAPIGatewayInvokeFullAccess"
}

resource "aws_iam_policy" "ws_lambda_policy" {
  name   = "WsLambdaPolicy"
  path   = "/"
  policy = data.aws_iam_policy_document.ws_lambda_policy.json
}

resource "aws_iam_policy" "ws_lambda_messenger_policy" {
  name   = "WsLambdaMessengerPolicy"
  path   = "/"
  policy = data.aws_iam_policy_document.ws_lambda_messenger_policy.json
}

resource "aws_iam_role" "ws_lambda_role" {
  name = "WsLambdaRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns = [aws_iam_policy.ws_lambda_policy.arn]
}

resource "aws_iam_role" "ws_lambda_messenger_role" {
  name = "WsLambdaMessengerRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns = [aws_iam_policy.ws_lambda_policy.arn, aws_iam_policy.ws_lambda_messenger_policy.arn, data.aws_iam_policy.apigw_invoke_access.arn]
}

resource "aws_lambda_function" "ws_messenger_lambda" {
  filename         = data.archive_file.ws_messenger_zip.output_path
  function_name    = "ws-messenger"
  role             = aws_iam_role.ws_lambda_messenger_role.arn
  handler          = "main.lambda_handler"
  runtime          = "python3.10"
  source_code_hash = data.archive_file.ws_messenger_zip.output_base64sha256
  environment {
    variables = {
      table             = "${aws_dynamodb_table.ws_messenger_table.id}",
      api_endpoint_url  = "https://${aws_apigatewayv2_api.ws_messenger_api_gateway.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_apigatewayv2_stage.ws_messenger_api_stage.name}"
    }
  }
}

resource "aws_lambda_function" "ws_authorizer_lambda" {
  filename         = data.archive_file.ws_authorizer_zip.output_path
  function_name    = "ws-authorizer"
  role             = aws_iam_role.ws_lambda_role.arn
  handler          = "main.lambda_handler"
  runtime          = "python3.10"
  source_code_hash = data.archive_file.ws_authorizer_zip.output_base64sha256
}

resource "aws_lambda_function" "ws_connect_lambda" {
  filename         = data.archive_file.ws_connect_zip.output_path
  function_name    = "ws-connect"
  role             = aws_iam_role.ws_lambda_role.arn
  handler          = "main.lambda_handler"
  runtime          = "python3.10"
  source_code_hash = data.archive_file.ws_connect_zip.output_base64sha256

  environment {
    variables = {
      table = "${aws_dynamodb_table.ws_messenger_table.id}"
    }
  }
}

resource "aws_lambda_function" "ws_disconnect_lambda" {
  filename         = data.archive_file.ws_disconnect_zip.output_path
  function_name    = "ws-disconnect"
  role             = aws_iam_role.ws_lambda_role.arn
  handler          = "main.lambda_handler"
  runtime          = "python3.10"
  source_code_hash = data.archive_file.ws_disconnect_zip.output_base64sha256

  environment {
    variables = {
      table = "${aws_dynamodb_table.ws_messenger_table.id}"
    }
  }
}

resource "aws_cloudwatch_log_group" "ws_messenger_logs" {
  name              = "/aws/lambda/${aws_lambda_function.ws_messenger_lambda.function_name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "ws_authorizer_logs" {
  name              = "/aws/lambda/${aws_lambda_function.ws_authorizer_lambda.function_name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "ws_connect_logs" {
  name              = "/aws/lambda/${aws_lambda_function.ws_connect_lambda.function_name}"
  retention_in_days = 30
}

data "aws_iam_policy_document" "ws_messenger_api_gateway_policy" {
  statement {
    actions = [
      "lambda:InvokeFunction",
    ]
    effect    = "Allow"
    resources = [
      aws_lambda_function.ws_messenger_lambda.arn, 
      aws_lambda_function.ws_authorizer_lambda.arn,
      aws_lambda_function.ws_connect_lambda.arn,
      aws_lambda_function.ws_disconnect_lambda.arn
    ]
  }
}

resource "aws_iam_policy" "ws_messenger_api_gateway_policy" {
  name   = "WsMessengerAPIGatewayPolicy"
  path   = "/"
  policy = data.aws_iam_policy_document.ws_messenger_api_gateway_policy.json
}

resource "aws_iam_role" "ws_messenger_api_gateway_role" {
  name = "WsMessengerAPIGatewayRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns = [aws_iam_policy.ws_messenger_api_gateway_policy.arn]
}

resource "aws_apigatewayv2_api" "ws_messenger_api_gateway" {
  name                       = "ws-messenger-api-gateway"
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

resource "aws_apigatewayv2_authorizer" "ws_messenger_api_authorizer" {
  api_id           = "${aws_apigatewayv2_api.ws_messenger_api_gateway.id}"
  authorizer_type  = "REQUEST"
  authorizer_uri   = "${aws_lambda_function.ws_authorizer_lambda.invoke_arn}"
  identity_sources = ["route.request.querystring.key"]
  name             = "ws-authorizer"
}

resource "aws_apigatewayv2_integration" "ws_messenger_connect_api_integration" {
  api_id                    = aws_apigatewayv2_api.ws_messenger_api_gateway.id
  integration_type          = "AWS_PROXY"
  integration_method       = "POST"
  integration_uri           = aws_lambda_function.ws_connect_lambda.invoke_arn
  credentials_arn           = aws_iam_role.ws_messenger_api_gateway_role.arn
  content_handling_strategy = "CONVERT_TO_TEXT"
  passthrough_behavior      = "WHEN_NO_MATCH"
}

resource "aws_apigatewayv2_integration" "ws_messenger_disconnect_api_integration" {
  api_id                    = aws_apigatewayv2_api.ws_messenger_api_gateway.id
  integration_type          = "AWS_PROXY"
  integration_method       = "POST"
  integration_uri           = aws_lambda_function.ws_disconnect_lambda.invoke_arn
  credentials_arn           = aws_iam_role.ws_messenger_api_gateway_role.arn
  content_handling_strategy = "CONVERT_TO_TEXT"
  passthrough_behavior      = "WHEN_NO_MATCH"
}

resource "aws_apigatewayv2_route" "ws_messenger_api_connect_route" {
  api_id    = aws_apigatewayv2_api.ws_messenger_api_gateway.id
  route_key = "$connect"
  target    = "integrations/${aws_apigatewayv2_integration.ws_messenger_connect_api_integration.id}"
  authorization_type = "CUSTOM"
  authorizer_id = aws_apigatewayv2_authorizer.ws_messenger_api_authorizer.id
}

resource "aws_apigatewayv2_route" "ws_messenger_api_disconnect_route" {
  api_id    = aws_apigatewayv2_api.ws_messenger_api_gateway.id
  route_key = "$disconnect"
  target    = "integrations/${aws_apigatewayv2_integration.ws_messenger_disconnect_api_integration.id}"
}

resource "aws_apigatewayv2_stage" "ws_messenger_api_stage" {
  api_id      = aws_apigatewayv2_api.ws_messenger_api_gateway.id
  name        = "develop"
  auto_deploy = true
}

resource "aws_lambda_permission" "ws_messenger_lambda_permissions" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ws_messenger_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.ws_messenger_api_gateway.execution_arn}/*/*"
}

resource "aws_lambda_permission" "ws_authorizer_lambda_permissions" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ws_authorizer_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.ws_messenger_api_gateway.execution_arn}/*/*"
}


resource "aws_dynamodb_table" "ws_messenger_table" {
  name           = "ws-connections-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "ConnectionID"
  attribute {
    name = "ConnectionID"
    type = "S"
  }
}