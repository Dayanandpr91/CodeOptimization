# PowerShell script for local security vulnerability analysis
# This script can be run locally to perform security scans before pushing to repository

param(
    [string]$ProjectPath = "CodeOptimization",
    [switch]$Verbose,
    [switch]$FixIssues
)

Write-Host "🔍 Starting Security Vulnerability Analysis..." -ForegroundColor Green

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Function to check if dotnet is installed
function Test-DotNetInstallation {
    try {
        $dotnetVersion = dotnet --version
        Write-ColorOutput "✅ .NET SDK Version: $dotnetVersion" "Green"
        return $true
    }
    catch {
        Write-ColorOutput "❌ .NET SDK not found. Please install .NET SDK." "Red"
        return $false
    }
}

# Function to check for vulnerable packages
function Test-PackageVulnerabilities {
    Write-ColorOutput "`n📦 Checking for vulnerable packages..." "Yellow"
    
    try {
        $vulnerablePackages = dotnet list "$ProjectPath/$ProjectPath.csproj" package --vulnerable --include-transitive 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ No vulnerable packages found" "Green"
        } else {
            Write-ColorOutput "⚠️ Vulnerable packages detected:" "Red"
            Write-Host $vulnerablePackages
            return $false
        }
    }
    catch {
        Write-ColorOutput "❌ Error checking package vulnerabilities: $_" "Red"
        return $false
    }
    
    return $true
}

# Function to check for outdated packages
function Test-OutdatedPackages {
    Write-ColorOutput "`n🔄 Checking for outdated packages..." "Yellow"
    
    try {
        $outdatedPackages = dotnet list "$ProjectPath/$ProjectPath.csproj" package --outdated --include-transitive
        
        if ($outdatedPackages -match "No packages were found") {
            Write-ColorOutput "✅ All packages are up to date" "Green"
        } else {
            Write-ColorOutput "⚠️ Outdated packages found:" "Yellow"
            Write-Host $outdatedPackages
        }
    }
    catch {
        Write-ColorOutput "❌ Error checking outdated packages: $_" "Red"
    }
}

# Function to analyze code for security issues
function Test-CodeSecurity {
    Write-ColorOutput "`n🔍 Analyzing code for security issues..." "Yellow"
    
    $securityIssues = @()
    
    # Check for weak random number generation
    $randomIssues = Select-String -Path "$ProjectPath/*.cs" -Pattern "new Random\(\)" -SimpleMatch
    if ($randomIssues) {
        $securityIssues += "CRITICAL: Weak random number generation found in: $($randomIssues.Filename)"
    }
    
    # Check for hardcoded secrets
    $secretPatterns = @("password\s*=\s*[\"'][^\"']+[\"']", "secret\s*=\s*[\"'][^\"']+[\"']", "key\s*=\s*[\"'][^\"']+[\"']")
    foreach ($pattern in $secretPatterns) {
        $secretIssues = Select-String -Path "$ProjectPath/*.cs" -Pattern $pattern
        if ($secretIssues) {
            $securityIssues += "HIGH: Potential hardcoded secrets found in: $($secretIssues.Filename)"
        }
    }
    
    # Check for SQL injection risks
    $sqlIssues = Select-String -Path "$ProjectPath/*.cs" -Pattern "string\.Format.*SELECT|string\.Concat.*SELECT"
    if ($sqlIssues) {
        $securityIssues += "HIGH: Potential SQL injection risk in: $($sqlIssues.Filename)"
    }
    
    # Check for missing input validation
    $validationIssues = Select-String -Path "$ProjectPath/*.cs" -Pattern "public.*\(.*string\s+\w+.*\)" | Where-Object { $_.Line -notmatch "null" -and $_.Line -notmatch "string\.IsNullOrEmpty" }
    if ($validationIssues) {
        $securityIssues += "MEDIUM: Missing input validation in: $($validationIssues.Filename)"
    }
    
    if ($securityIssues.Count -eq 0) {
        Write-ColorOutput "✅ No obvious security issues found in code analysis" "Green"
    } else {
        Write-ColorOutput "⚠️ Security issues found:" "Red"
        foreach ($issue in $securityIssues) {
            Write-ColorOutput "  - $issue" "Red"
        }
    }
    
    return $securityIssues
}

# Function to generate security report
function New-SecurityReport {
    param([array]$Issues)
    
    $reportPath = "security-scan-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
    
    $report = @"
# Security Scan Report
Generated: $(Get-Date)

## Summary
- Total Issues Found: $($Issues.Count)
- Scan Status: $(if ($Issues.Count -eq 0) { "✅ PASSED" } else { "⚠️ ISSUES FOUND" })

## Issues Found
"@

    if ($Issues.Count -gt 0) {
        foreach ($issue in $Issues) {
            $report += "`n- $issue"
        }
    } else {
        $report += "`n✅ No security issues found."
    }
    
    $report += @"

## Recommendations
1. Update all outdated packages to latest versions
2. Replace `new Random()` with `RandomNumberGenerator` for cryptographic purposes
3. Add input validation to all public methods
4. Implement proper error handling
5. Use parameterized queries for database operations
6. Avoid hardcoding secrets in source code

## Next Steps
1. Review and fix all identified issues
2. Run this scan again to verify fixes
3. Consider implementing automated security scanning in CI/CD pipeline
"@

    $report | Out-File -FilePath $reportPath -Encoding UTF8
    Write-ColorOutput "`n📄 Security report generated: $reportPath" "Green"
}

# Main execution
Write-ColorOutput "🚀 Security Vulnerability Analysis Tool" "Cyan"
Write-ColorOutput "=====================================" "Cyan"

# Check prerequisites
if (-not (Test-DotNetInstallation)) {
    exit 1
}

# Change to project directory
if (Test-Path $ProjectPath) {
    Set-Location $ProjectPath
} else {
    Write-ColorOutput "❌ Project directory not found: $ProjectPath" "Red"
    exit 1
}

# Run security checks
$allIssues = @()

# Check package vulnerabilities
if (-not (Test-PackageVulnerabilities)) {
    $allIssues += "Vulnerable packages detected"
}

# Check outdated packages
Test-OutdatedPackages

# Analyze code security
$codeIssues = Test-CodeSecurity
$allIssues += $codeIssues

# Generate report
New-SecurityReport -Issues $allIssues

# Summary
Write-ColorOutput "`n📊 Scan Summary:" "Cyan"
Write-ColorOutput "=================" "Cyan"
Write-ColorOutput "Total Issues: $($allIssues.Count)" $(if ($allIssues.Count -eq 0) { "Green" } else { "Red" })

if ($allIssues.Count -gt 0) {
    Write-ColorOutput "`n⚠️ Security issues found. Please review and fix before pushing to repository." "Red"
    exit 1
} else {
    Write-ColorOutput "`n✅ Security scan passed. Code is ready for repository push." "Green"
    exit 0
}
