resource "aws_budgets_budget" "ec2" {
  name              = "budget-ec2-monthly"
  budget_type       = "COST"
  limit_amount      = "5"
  limit_unit        = "USD"
  time_period_end   = "2087-06-15_00:00"
  time_period_start = "2017-07-01_00:00"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 75
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = ["thrashr888@gmail.com"]
  }
}

check "check_budget_exceeded" {
  data "aws_budgets_budget" "example" {
    name = aws_budgets_budget.ec2.name
  }

  assert {
    condition = !data.aws_budgets_budget.example.budget_exceeded
    error_message = format("AWS budget has been exceeded! Calculated spend: '%s' and budget limit: '%s'",
      data.aws_budgets_budget.example.calculated_spend[0].actual_spend[0].amount,
      data.aws_budgets_budget.example.budget_limit[0].amount
    )
  }
}

# --------------------------------
# resource "aws_guardduty_detector" "example" {
#   enable = true

#   datasources {
#     s3_logs {
#       enable = true
#     }
#     kubernetes {
#       audit_logs {
#         enable = false
#       }
#     }
#     malware_protection {
#       scan_ec2_instance_with_findings {
#         ebs_volumes {
#           enable = true
#         }
#       }
#     }
#   }
# }

# # data "aws_guardduty_detector" "example" {}

# check "check_guardduty_findings" {
#   data "aws_guardduty_finding_ids" "example" {
#     detector_id = aws_guardduty_detector.example.id
#   }

#   assert {
#     condition = !data.aws_guardduty_finding_ids.example.has_findings
#     error_message = format("AWS GuardDuty detector '%s' has %d open findings!",
#       data.aws_guardduty_finding_ids.example.detector_id,
#       length(data.aws_guardduty_finding_ids.example.finding_ids),
#     )
#   }
# }
