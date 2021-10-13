variable "prj_name" {}

resource "aws_s3_bucket" "nwfw_log" {
  bucket = "${var.prj_name}-nwfw-log"
  acl    = "private"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  tags = {
    Name = "${var.prj_name}-nwfw-log"
  }
}

resource "aws_s3_bucket" "lb_log" {
  bucket = "${var.prj_name}-lb-log"
  acl    = "private"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  tags = {
    Name = "${var.prj_name}-lb-log"
  }
}

data "aws_elb_service_account" "main" {}

data "aws_iam_policy_document" "lb_log" {
  statement {
    effect    = "Allow"
    actions   = [ "s3:PutObject" ]
    resources = [ "${aws_s3_bucket.lb_log.arn}/*" ]
    principals {
      type = "AWS"
      identifiers = [ data.aws_elb_service_account.main.arn ]
    }
  }
}

resource "aws_s3_bucket_policy" "nlb_logs" {
  bucket = aws_s3_bucket.lb_log.id
  policy = data.aws_iam_policy_document.lb_log.json
}

output nwfw_log_bucket { value = aws_s3_bucket.nwfw_log.bucket }
output lb_log_bucket { value = aws_s3_bucket.lb_log.bucket }