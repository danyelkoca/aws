# Kinesis Firehose Example: Web Analytics Pipeline

This example demonstrates using Kinesis Firehose to build a web analytics pipeline with the following features:

- JSON to Parquet conversion
- S3 data lake storage
- Partitioning by time
- Raw data backup
- Athena querying capability

## Components

1. **Infrastructure (`firehose.tf`)**

   - Kinesis Firehose delivery stream
   - S3 buckets for processed and raw data
   - Glue catalog for data schema
   - Athena workgroup and query setup

2. **Log Producer (`producer.py`)**
   - Generates realistic web server logs
   - Sends data directly to Firehose
   - Simulates various HTTP requests and response patterns

## Setup and Testing

1. **Deploy Infrastructure**

   ```bash
   terraform init
   terraform apply
   ```

2. **Install Dependencies**

   ```bash
   python3 -m venv .venv
   source .venv/bin/activate
   pip install -r requirements.txt
   ```

3. **Generate Test Data**

   ```bash
   python producer.py
   ```

   Let it run for a few minutes to generate sufficient data.

4. **Query Data with Athena**

   Wait at least 2-3 minutes after sending data (due to Firehose's 60s buffer), then use these sample queries in Athena:

   ```sql
   -- Check recent data
   SELECT *
   FROM web_analytics.web_logs
   ORDER BY timestamp DESC
   LIMIT 10;

   -- Error rate analysis
   SELECT
     CONCAT(year, '-', month, '-', day, ' ', hour, ':00') as hour,
     COUNT(CASE WHEN status_code >= 400 THEN 1 END) * 100.0 / COUNT(*) as error_rate,
     COUNT(*) as total_requests
   FROM web_analytics.web_logs
   GROUP BY year, month, day, hour
   ORDER BY year, month, day, hour DESC;

   -- Performance analysis
   SELECT
     path,
     COUNT(*) as requests,
     AVG(response_time) as avg_response_time,
     MAX(response_time) as max_response_time
   FROM web_analytics.web_logs
   GROUP BY path
   ORDER BY avg_response_time DESC;
   ```

5. **Cleanup**
   ```bash
   terraform destroy
   deactivate  # Exit virtual environment
   ```

## Cost Considerations

- Firehose: \$0.029 per GB processed
- S3: Storage costs + Lifecycle management
- Athena: \$5 per TB scanned (but Parquet format significantly reduces scan costs)

## Key Features

1. **Data Transformation**

   - JSON to Parquet conversion
   - Reduces storage costs and query time
   - Enables efficient analytics

2. **Data Organization**

   - Partitioned by year/month/day/hour
   - Separate buckets for processed and raw data
   - Lifecycle rules for cost management

3. **Analytics Ready**
   - Preconfigured Athena workgroup
   - Sample queries provided
   - Optimized table structure

## Requirements

- Python 3.x
- AWS credentials configured locally
- Terraform
- AWS Athena access
