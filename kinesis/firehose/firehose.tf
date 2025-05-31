# Variable for AWS region
variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "ap-northeast-1"
}

# Configure AWS Provider
provider "aws" {
  region = var.aws_region
}

# Data source for AWS account ID (used in IAM policies)
data "aws_caller_identity" "current" {}

######################
# S3 Buckets        #
######################

# Bucket for raw JSON data
resource "aws_s3_bucket" "raw_data" {
  bucket_prefix = "web-analytics-raw-"
  force_destroy = true
}

# Bucket for processed Parquet data
resource "aws_s3_bucket" "processed_data" {
  bucket_prefix = "web-analytics-processed-"
  force_destroy = true
}

# S3 bucket for Athena query results
resource "aws_s3_bucket" "athena_results" {
  bucket_prefix = "web-analytics-athena-"
  force_destroy = true
}

######################
# IAM Roles         #
######################

# IAM in AWS is used to manage access and permissions for AWS resources.
# Typically, you create an IAM role with a trust policy that defines which AWS service or user can assume the role (the principal).
# Then, you attach one or more policies to the role to specify what actions are allowed.
# In this configuration, we create a role for Kinesis Firehose and allow it to assume the role.
# We then attach a policy that grants Firehose permissions to interact with the specified S3 buckets.

# IAM role for Firehose
resource "aws_iam_role" "firehose_role" {
  name = "firehose-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      }
    ]
  })
} # Policy to allow Firehose to write to S3 and access Glue
resource "aws_iam_role_policy" "firehose_s3" {
  name = "firehose-s3-policy"
  role = aws_iam_role.firehose_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.raw_data.arn,
          "${aws_s3_bucket.raw_data.arn}/*",
          aws_s3_bucket.processed_data.arn,
          "${aws_s3_bucket.processed_data.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "glue:GetTableVersions",
          "glue:GetTable",
          "glue:GetDatabase"
        ],
        Resource = [
          "arn:aws:glue:${var.aws_region}:${data.aws_caller_identity.current.account_id}:catalog",
          "arn:aws:glue:${var.aws_region}:${data.aws_caller_identity.current.account_id}:database/${aws_glue_catalog_database.web_analytics.name}",
          "arn:aws:glue:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${aws_glue_catalog_database.web_analytics.name}/${aws_glue_catalog_table.web_logs.name}"
        ]
      }
    ]
  })
}

# IAM role for Athena
resource "aws_iam_role" "athena_role" {
  name = "athena-analytics-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "athena.amazonaws.com"
        }
      }
    ]
  })
}

# Policy for Athena to access S3 and Glue
resource "aws_iam_role_policy" "athena_policy" {
  name = "athena-analytics-policy"
  role = aws_iam_role.athena_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Read access to processed data
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.processed_data.arn,
          "${aws_s3_bucket.processed_data.arn}/*"
        ]
      },
      {
        # Write access for query results
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads"
        ]
        Resource = [
          aws_s3_bucket.athena_results.arn,
          "${aws_s3_bucket.athena_results.arn}/*"
        ]
      },
      {
        # Glue catalog access
        Effect = "Allow"
        Action = [
          "glue:GetTable",
          "glue:GetPartitions",
          "glue:GetDatabase",
          "glue:GetTables",
          "glue:GetDatabases",
          "glue:GetPartition"
        ]
        Resource = [
          "arn:aws:glue:${var.aws_region}:${data.aws_caller_identity.current.account_id}:catalog",
          "arn:aws:glue:${var.aws_region}:${data.aws_caller_identity.current.account_id}:database/${aws_glue_catalog_database.web_analytics.name}",
          "arn:aws:glue:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${aws_glue_catalog_database.web_analytics.name}/*"
        ]
      }
    ]
  })
}

######################
# Kinesis Firehose  #
######################

resource "aws_kinesis_firehose_delivery_stream" "web_analytics" {
  name        = "web-analytics-stream"
  destination = "extended_s3"

  # Data transformation - Convert to Parquet and add enrichments
  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.processed_data.arn

    # Buffer conditions - Using minimum values required for Parquet conversion
    buffering_size     = 64 # 64 MB minimum for Parquet conversion
    buffering_interval = 60 # 60 seconds

    # Write raw JSON to raw bucket
    s3_backup_mode = "Enabled"
    s3_backup_configuration {
      role_arn   = aws_iam_role.firehose_role.arn
      bucket_arn = aws_s3_bucket.raw_data.arn
      prefix     = "raw/"
    }

    # Write processed Parquet to processed bucket
    prefix              = "processed/"
    error_output_prefix = "errors/"

    # Data format conversion from JSON to Parquet
    data_format_conversion_configuration {
      input_format_configuration {
        deserializer {
          hive_json_ser_de {}
        }
      }

      output_format_configuration {
        serializer {
          parquet_ser_de {}
        }
      }

      schema_configuration {
        database_name = aws_glue_catalog_database.web_analytics.name
        table_name    = aws_glue_catalog_table.web_logs.name
        region        = var.aws_region
        role_arn      = aws_iam_role.firehose_role.arn
      }
    }
  }
}

######################
# Glue Catalog      #
######################

# Glue catalog database
resource "aws_glue_catalog_database" "web_analytics" {
  name = "web_analytics"
}

# Glue catalog table for the web logs
resource "aws_glue_catalog_table" "web_logs" {
  name          = "web_logs"
  database_name = aws_glue_catalog_database.web_analytics.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL              = "TRUE"
    "classification"      = "parquet"
    "parquet.compression" = "SNAPPY"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.processed_data.id}/processed"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      name                  = "ParquetHiveSerDe"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
    }

    # Define the schema for our web logs
    columns {
      name = "timestamp"
      type = "string"
    }
    columns {
      name = "ip_address"
      type = "string"
    }
    columns {
      name = "user_agent"
      type = "string"
    }
    columns {
      name = "http_method"
      type = "string"
    }
    columns {
      name = "path"
      type = "string"
    }
    columns {
      name = "status_code"
      type = "int"
    }
    columns {
      name = "response_time"
      type = "double"
    }
  }
}

######################
# Athena Resources  #
######################



# Athena workgroup
resource "aws_athena_workgroup" "analytics" {
  name = "web_analytics_workgroup"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = false

    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/output/"
    }
  }
}

######################
# Outputs           #
######################

output "firehose_stream_name" {
  description = "The name of the Kinesis Firehose delivery stream"
  value       = aws_kinesis_firehose_delivery_stream.web_analytics.name
}

output "processed_bucket_name" {
  description = "Name of the S3 bucket containing processed data"
  value       = aws_s3_bucket.processed_data.id
}

output "athena_workgroup" {
  description = "Name of the Athena workgroup"
  value       = aws_athena_workgroup.analytics.name
}

output "sample_athena_queries" {
  description = "Sample Athena queries to analyze the data"
  value       = <<EOF
-- Count requests by status code in the last hour
SELECT status_code, COUNT(*) as count
FROM web_logs
WHERE year = '!{format_date('yyyy')}'
  AND month = '!{format_date('MM')}'
  AND day = '!{format_date('dd')}'
  AND hour = '!{format_date('HH')}'
GROUP BY status_code
ORDER BY count DESC;

-- Top 10 paths by response time
SELECT path, 
       AVG(response_time) as avg_response_time,
       COUNT(*) as request_count
FROM web_logs
GROUP BY path
ORDER BY avg_response_time DESC
LIMIT 10;

-- Error rate by hour
SELECT 
  CONCAT(year, '-', month, '-', day, ' ', hour, ':00') as hour,
  COUNT(CASE WHEN status_code >= 400 THEN 1 END) * 100.0 / COUNT(*) as error_rate,
  COUNT(*) as total_requests
FROM web_logs
GROUP BY year, month, day, hour
ORDER BY year, month, day, hour DESC;
EOF
}
