param(
    [Parameter(Mandatory = $true)]
    [string]$TargetOrg
)

$ErrorActionPreference = "Stop"

Write-Host "Assigning Real_Estate_Manager permission set..."
sf org assign permset --name Real_Estate_Manager --target-org "$TargetOrg"

Write-Host "Scheduling lease reminder job..."
sf apex run --file scripts/scheduleLeaseReminders.apex --target-org "$TargetOrg"

Write-Host "Importing sample data..."
sf data import tree --plan data/RealEstatePlan.json --target-org "$TargetOrg"

Write-Host "Running local Apex tests with coverage..."
sf apex run test --target-org "$TargetOrg" --test-level RunLocalTests --code-coverage --wait 20

Write-Host "Post-deploy automation complete."
