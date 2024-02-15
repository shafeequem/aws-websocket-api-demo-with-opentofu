/*
resource "aws_vpc" "main" {
  cidr_block = var.base_cidr_block
   tags = {
    Name = "tofu-vpc"
  }
}

resource "aws_subnet" "az" {
  count = length(var.availability_zones)
  availability_zone = var.availability_zones[count.index]
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 4, count.index+1)
}

*/
data "aws_iam_policy_document" "ws_messenger_lambda_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect    = "Allow"
    resources = ["arn:aws:logs:*:*:*"]
  }
}

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

resource "aws_iam_policy" "ws_messenger_lambda_policy" {
  name   = "WsMessengerLambdaPolicy"
  path   = "/"
  policy = data.aws_iam_policy_document.ws_messenger_lambda_policy.json
}

resource "aws_iam_role" "ws_messenger_lambda_role" {
  name = "WsMessengerLambdaRole"

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

  managed_policy_arns = [aws_iam_policy.ws_messenger_lambda_policy.arn]
}

resource "aws_lambda_function" "ws_messenger_lambda" {
  filename         = data.archive_file.ws_messenger_zip.output_path
  function_name    = "ws-messenger"
  role             = aws_iam_role.ws_messenger_lambda_role.arn
  handler          = "main"
  runtime          = "python3.10"
  source_code_hash = data.archive_file.ws_messenger_zip.output_base64sha256
}

resource "aws_lambda_function" "ws_authorizer_lambda" {
  filename         = data.archive_file.ws_authorizer_zip.output_path
  function_name    = "ws-authorizer"
  role             = aws_iam_role.ws_messenger_lambda_role.arn
  handler          = "main"
  runtime          = "python3.10"
  source_code_hash = data.archive_file.ws_authorizer_zip.output_base64sha256
}

resource "aws_cloudwatch_log_group" "ws_messenger_logs" {
  name              = "/aws/lambda/${aws_lambda_function.ws_messenger_lambda.function_name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "ws_authorizer_logs" {
  name              = "/aws/lambda/${aws_lambda_function.ws_authorizer_lambda.function_name}"
  retention_in_days = 30
}

data "aws_iam_policy_document" "ws_messenger_api_gateway_policy" {
  statement {
    actions = [
      "lambda:InvokeFunction",
    ]
    effect    = "Allow"
    resources = [aws_lambda_function.ws_messenger_lambda.arn, aws_lambda_function.ws_authorizer_lambda.arn]
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
  identity_sources = ["route.request.header.Auth"]
  name             = "ws-authorizer"
}

resource "aws_apigatewayv2_integration" "ws_messenger_api_integration" {
  api_id                    = aws_apigatewayv2_api.ws_messenger_api_gateway.id
  integration_type          = "AWS_PROXY"
  integration_uri           = aws_lambda_function.ws_messenger_lambda.invoke_arn
  credentials_arn           = aws_iam_role.ws_messenger_api_gateway_role.arn
  content_handling_strategy = "CONVERT_TO_TEXT"
  passthrough_behavior      = "WHEN_NO_MATCH"
}

resource "aws_apigatewayv2_integration_response" "ws_messenger_api_integration_response" {
  api_id                   = aws_apigatewayv2_api.ws_messenger_api_gateway.id
  integration_id           = aws_apigatewayv2_integration.ws_messenger_api_integration.id
  integration_response_key = "/200/"
}

/*
resource "aws_apigatewayv2_route" "ws_messenger_api_default_route" {
  api_id    = aws_apigatewayv2_api.ws_messenger_api_gateway.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.ws_messenger_api_integration.id}"
}

resource "aws_apigatewayv2_route_response" "ws_messenger_api_default_route_response" {
  api_id             = aws_apigatewayv2_api.ws_messenger_api_gateway.id
  route_id           = aws_apigatewayv2_route.ws_messenger_api_default_route.id
  route_response_key = "$default"
}
*/

resource "aws_apigatewayv2_route" "ws_messenger_api_connect_route" {
  api_id    = aws_apigatewayv2_api.ws_messenger_api_gateway.id
  route_key = "$connect"
  target    = "integrations/${aws_apigatewayv2_integration.ws_messenger_api_integration.id}"
  authorization_type = "CUSTOM"
  authorizer_id = aws_apigatewayv2_authorizer.ws_messenger_api_authorizer.id
}

/*
resource "aws_apigatewayv2_route_response" "ws_messenger_api_connect_route_response" {
  api_id             = aws_apigatewayv2_api.ws_messenger_api_gateway.id
  route_id           = aws_apigatewayv2_route.ws_messenger_api_connect_route.id
  route_response_key = "$default"
}
*/

resource "aws_apigatewayv2_route" "ws_messenger_api_disconnect_route" {
  api_id    = aws_apigatewayv2_api.ws_messenger_api_gateway.id
  route_key = "$disconnect"
  target    = "integrations/${aws_apigatewayv2_integration.ws_messenger_api_integration.id}"
}
/*
resource "aws_apigatewayv2_route_response" "ws_messenger_api_disconnect_route_response" {
  api_id             = aws_apigatewayv2_api.ws_messenger_api_gateway.id
  route_id           = aws_apigatewayv2_route.ws_messenger_api_disconnect_route.id
  route_response_key = "$default"
}

resource "aws_apigatewayv2_route" "ws_messenger_api_message_route" {
  api_id    = aws_apigatewayv2_api.ws_messenger_api_gateway.id
  route_key = "MESSAGE"
  target    = "integrations/${aws_apigatewayv2_integration.ws_messenger_api_integration.id}"
}

resource "aws_apigatewayv2_route_response" "ws_messenger_api_message_route_response" {
  api_id             = aws_apigatewayv2_api.ws_messenger_api_gateway.id
  route_id           = aws_apigatewayv2_route.ws_messenger_api_message_route.id
  route_response_key = "$default"
}
*/

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