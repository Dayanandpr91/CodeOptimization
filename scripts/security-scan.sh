#!/bin/bash

# Bash script for local security vulnerability analysis
# This script can be run locally to perform security scans before pushing to repository

set -e

PROJECT_PATH="CodeOptimization"
VERBOSE=false
FIX_ISSUES=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if dotnet is installed
check_dotnet() {
    if command -v dotnet &> /dev/null; then
        local version=$(dotnet --version)
        print_color $GREEN "✅ .NET SDK Version: $version"
        return 0
    else
        print_color $RED "❌ .NET SDK not found. Please install .NET SDK."
        return 1
    fi
}

# Function to check for vulnerable packages
check_package_vulnerabilities() {
    print_color $YELLOW "📦 Checking for vulnerable packages..."
    
    if dotnet list "$PROJECT_PATH/$PROJECT_PATH.csproj" package --vulnerable --include-transitive > /dev/null 2>&1; then
        print_color $GREEN "✅ No vulnerable packages found"
        return 0
    else
        print_color $RED "⚠️ Vulnerable packages detected:"
        dotnet list "$PROJECT_PATH/$PROJECT_PATH.csproj" package --vulnerable --include-transitive
        return 1
    fi
}

# Function to check for outdated packages
check_outdated_packages() {
    print_color $YELLOW "🔄 Checking for outdated packages..."
    
    local outdated_output=$(dotnet list "$PROJECT_PATH/$PROJECT_PATH.csproj" package --outdated --include-transitive)
    
    if echo "$outdated_output" | grep -q "No packages were found"; then
        print_color $GREEN "✅ All packages are up to date"
    else
        print_color $YELLOW "⚠️ Outdated packages found:"
        echo "$outdated_output"
    fi
}

# Function to analyze code for security issues
analyze_code_security() {
    print_color $YELLOW "🔍 Analyzing code for security issues..."
    
    local issues=()
    
    # Check for weak random number generation
    if grep -r "new Random()" "$PROJECT_PATH"/*.cs > /dev/null 2>&1; then
        issues+=("CRITICAL: Weak random number generation found")
    fi
    
    # Check for hardcoded secrets
    if grep -rE "(password|secret|key|token)\s*=\s*[\"'][^\"']+[\"']" "$PROJECT_PATH"/*.cs > /dev/null 2>&1; then
        issues+=("HIGH: Potential hardcoded secrets found")
    fi
    
    # Check for SQL injection risks
    if grep -rE "string\.Format.*SELECT|string\.Concat.*SELECT" "$PROJECT_PATH"/*.cs > /dev/null 2>&1; then
        issues+=("HIGH: Potential SQL injection risk found")
    fi
    
    # Check for missing input validation
    if grep -rE "public.*\(.*string\s+\w+.*\)" "$PROJECT_PATH"/*.cs | grep -v "null" | grep -v "string\.IsNullOrEmpty" > /dev/null 2>&1; then
        issues+=("MEDIUM: Missing input validation found")
    fi
    
    if [ ${#issues[@]} -eq 0 ]; then
        print_color $GREEN "✅ No obvious security issues found in code analysis"
    else
        print_color $RED "⚠️ Security issues found:"
        for issue in "${issues[@]}"; do
            print_color $RED "  - $issue"
        done
    fi
    
    printf '%s\n' "${issues[@]}"
}

# Function to generate security report
generate_security_report() {
    local issues=("$@")
    local timestamp=$(date +"%Y%m%d-%H%M%S")
    local report_path="security-scan-report-$timestamp.md"
    
    cat > "$report_path" << EOF
# Security Scan Report
Generated: $(date)

## Summary
- Total Issues Found: ${#issues[@]}
- Scan Status: $(if [ ${#issues[@]} -eq 0 ]; then echo "✅ PASSED"; else echo "⚠️ ISSUES FOUND"; fi)

## Issues Found
EOF

    if [ ${#issues[@]} -gt 0 ]; then
        for issue in "${issues[@]}"; do
            echo "- $issue" >> "$report_path"
        done
    else
        echo "✅ No security issues found." >> "$report_path"
    fi
    
    cat >> "$report_path" << EOF

## Recommendations
1. Update all outdated packages to latest versions
2. Replace \`new Random()\` with \`RandomNumberGenerator\` for cryptographic purposes
3. Add input validation to all public methods
4. Implement proper error handling
5. Use parameterized queries for database operations
6. Avoid hardcoding secrets in source code

## Next Steps
1. Review and fix all identified issues
2. Run this scan again to verify fixes
3. Consider implementing automated security scanning in CI/CD pipeline
EOF

    print_color $GREEN "📄 Security report generated: $report_path"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -p, --project PATH    Project path (default: CodeOptimization)"
    echo "  -v, --verbose         Enable verbose output"
    echo "  -f, --fix             Attempt to fix issues automatically"
    echo "  -h, --help            Show this help message"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--project)
            PROJECT_PATH="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -f|--fix)
            FIX_ISSUES=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main execution
print_color $CYAN "🚀 Security Vulnerability Analysis Tool"
print_color $CYAN "====================================="

# Check prerequisites
if ! check_dotnet; then
    exit 1
fi

# Check if project directory exists
if [ ! -d "$PROJECT_PATH" ]; then
    print_color $RED "❌ Project directory not found: $PROJECT_PATH"
    exit 1
fi

# Run security checks
all_issues=()

# Check package vulnerabilities
if ! check_package_vulnerabilities; then
    all_issues+=("Vulnerable packages detected")
fi

# Check outdated packages
check_outdated_packages

# Analyze code security
code_issues=($(analyze_code_security))
all_issues+=("${code_issues[@]}")

# Generate report
generate_security_report "${all_issues[@]}"

# Summary
print_color $CYAN "📊 Scan Summary:"
print_color $CYAN "================="

if [ ${#all_issues[@]} -eq 0 ]; then
    print_color $GREEN "Total Issues: ${#all_issues[@]}"
    print_color $GREEN "✅ Security scan passed. Code is ready for repository push."
    exit 0
else
    print_color $RED "Total Issues: ${#all_issues[@]}"
    print_color $RED "⚠️ Security issues found. Please review and fix before pushing to repository."
    exit 1
fi
