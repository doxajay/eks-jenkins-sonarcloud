resource "aws_cloudwatch_log_group" "jenkins" {
  name              = "/acme/jenkins"
  retention_in_days = 14
}

resource "aws_cloudwatch_metric_alarm" "jenkins_cpu_high" {
  alarm_name          = "Jenkins-CPU-High"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  threshold           = 80
  period              = 120
  statistic           = "Average"
  alarm_description   = "CPU > 80% on Jenkins EC2"
  dimensions = {
    InstanceId = aws_instance.jenkins.id
  }
}
