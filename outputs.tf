/*
output "ws_api_url" {
  value = aws_apigatewayv2_stage.ws_messenger_api_stage.invoke_url
}
*/

output "website_url" {
  value = "http://${aws_s3_bucket.ws_app.bucket}.s3-website.${var.aws_region}.amazonaws.com"
}

output "messenger_lambda" {
  value = aws_lambda_function.ws_messenger_lambda.function_name
}