# Kinesis Data Streams Example: Web Server Log Analysis

This example demonstrates real-time log analysis using Amazon Kinesis Data Streams. It simulates a web server logging system with real-time monitoring capabilities.

## Components

1. **Infrastructure (`datastreams.tf`)**

   - Single-shard Kinesis Data Stream
   - Minimum retention period (24 hours)
   - Cost-optimized configuration

2. **Log Producer (`producer.py`)**

   - Generates realistic web server logs
   - Simulates various HTTP requests, response times, and status codes
   - Sends data to Kinesis stream in real-time

3. **Log Consumer (`consumer.py`)**
   - Reads logs from the Kinesis stream in real-time
   - Performs basic analytics:
     - Top active IP addresses
     - Path status code distribution
     - Recent error tracking
     - Response time monitoring

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

3. **Run the Example**

   - In one terminal: `python producer.py`
   - In another terminal: `python consumer.py`

4. **Cleanup**
   ```bash
   terraform destroy
   deactivate  # Exit virtual environment
   ```

## Cost Considerations

- Uses minimum configuration (1 shard)
- Base cost ≈ \$0.015 per hour
- Additional costs based on data volume

## Requirements

- Python 3.x
- AWS credentials configured locally
- Terraform
- Required Python packages (see requirements.txt)
