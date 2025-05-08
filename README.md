# AWS Solutions Architect Professional (SAP-C02) Study Guide

This repository contains code and notes created while following [Andrew Brown's AWS Solutions Architect Professional certification course](https://www.youtube.com/watch?v=hyEw7dQ9-JE).

## Course Overview

The AWS Solutions Architect Professional certification validates advanced knowledge in:

- Designing complex cloud solutions
- Optimizing for security, cost, and performance
- Automating manual processes

## Topics Covered

- S3, VPC, Lambda, CloudFront
- Database services (RDS, Aurora, DynamoDB, Neptune)
- Compute (EC2, ECS, EKS)
- Messaging (SQS, SNS, MSK)
- Storage solutions (EBS, EFS, FSx)
- Migration services
- Serverless architecture
- Security services

## Repository Structure

This repository organizes code examples and notes for each major AWS service covered in the certification exam.

## Setup Requirements

### Prerequisites

- Python 3.10 or higher
- AWS CLI
- Node.js 18.x
- AWS CDK
- Terraform
- Git

### Installation Steps

1. **Install AWS CLI**

   ```bash
   # macOS (using Homebrew)
   brew install awscli

   # Verify installation
   aws --version
   ```

2. **Configure AWS CLI**

   ```bash
   aws configure
   # You'll need to enter:
   # - AWS Access Key ID
   # - AWS Secret Access Key
   # - Default region name (e.g., us-east-1)
   # - Default output format (json)
   ```

3. **Install Node.js and AWS CDK**

   ```bash
   # Install Node.js using Homebrew
   brew install node@18

   # Install AWS CDK globally
   npm install -g aws-cdk
   ```

4. **Install Terraform**

   ```bash
   # Install Terraform using Homebrew
   brew install terraform
   ```

5. **Set up Python Virtual Environment**

   ```bash
   # Create virtual environment
   python3 -m venv .venv

   # Activate virtual environment
   source .venv/bin/activate
   ```

6. **Install Dependencies**

   ```bash
   # Install all dependencies (including development tools)
   pip install -r requirements-dev.txt
   ```

### Development Tools

The project includes several development tools:

- `black`: Code formatter
- `flake8`: Linter
- `isort`: Import sorter
- `pytest`: Testing framework
- `pre-commit`: Git hooks

## Resources

- [AWS Documentation](https://docs.aws.amazon.com/)
- [Youtube Video](https://www.youtube.com/watch?v=hyEw7dQ9-JE)
