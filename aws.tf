check "check_budget_exceeded" {
  data "aws_budgets_budget" "example" {
    name = aws_budgets_budget.example.name
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

data "aws_guardduty_detector" "example" {}
 
check "check_guardduty_findings" {
  data "aws_guardduty_finding_ids" "example" {
    detector_id = data.aws_guardduty_detector.example.id
  }
 
  assert {
    condition = !data.aws_guardduty_finding_ids.example.has_findings
    error_message = format("AWS GuardDuty detector '%s' has %d open findings!",
      data.aws_guardduty_finding_ids.example.detector_id,
      length(data.aws_guardduty_finding_ids.example.finding_ids),
    )
  }
}
