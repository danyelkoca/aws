# Amazon Kinesis

## Overview

Amazon Kinesis is a platform for streaming data on AWS, making it easy to collect, process, and analyze real-time, streaming data.

### Kinesis vs Other Messaging Services

| Feature          | Kinesis Data Streams                      | SQS                          | SNS                                       |
| ---------------- | ----------------------------------------- | ---------------------------- | ----------------------------------------- |
| Primary Use Case | Real-time streaming data processing       | Decoupled message processing | Pub/sub messaging                         |
| Data Retention   | Up to 365 days                            | Up to 14 days                | No retention (immediate delivery)         |
| Processing Model | Multiple consumers can read the same data | Single consumer per message  | Multiple subscribers receive same message |
| Throughput       | High-throughput, real-time (MB/sec)       | Message-based throughput     | Fan-out message delivery                  |
| Order Guarantee  | Per-shard ordering                        | FIFO queues available        | No ordering guarantee                     |
| Scalability      | Shard-based scaling                       | Automatic scaling            | Automatic scaling                         |

### Common Use Cases

1. **Log and Event Data Collection**

   - Application logs
   - System metrics
   - User activity tracking

2. **Real-time Analytics**

   - Gaming analytics
   - Social media sentiment
   - Stock market data processing

3. **IoT Device Data**

   - Sensor data processing
   - Connected device telemetry
   - Industrial monitoring

4. **Click Stream Analysis**
   - Website user behavior
   - Mobile app analytics
   - A/B testing data

## Kinesis Services

### 1. Kinesis Data Streams (KDS)

- Real-time streaming service for ingesting data
- Data organized in shards
- Multiple applications can consume same data
- Manual scaling via shard management
- Pay per shard hour

### 2. Kinesis Data Firehose

- Fully managed service to load streaming data into destinations
- Automatic scaling
- Near real-time delivery with 60s minimum batching interval
  - Data is buffered for at least 60 seconds before being delivered
  - Designed for batch processing, not real-time operations
  - Suitable for data warehousing and analytics use cases
- No data storage management needed
- Pay for data volume processed

### 3. Kinesis Data Analytics

- Real-time analytics using SQL or Apache Flink
- Process and analyze streaming data
- Automatic scaling
- Pay for actual consumption

### 4. Kinesis Video Streams

- Stream video from connected devices
- Real-time and batch video processing
- Durable storage
- Pay for data volume and storage used

## Service Comparison

| Feature        | Data Streams                     | Firehose                                   |
| -------------- | -------------------------------- | ------------------------------------------ |
| Latency        | Real-time (200ms)                | Near real-time (min 60s)                   |
| Management     | Manual shard management          | Fully managed                              |
| Integration    | Custom consumers                 | Built-in destinations (S3, Redshift, etc.) |
| Scaling        | Manual (shard splitting/merging) | Automatic                                  |
| Data Retention | 24h to 365 days                  | No retention (immediate delivery)          |
| Processing     | Raw access to data               | Optional data transformation               |
| Use Case       | Real-time processing             | Data loading and ETL                       |
| Cost Model     | Per shard hour                   | Per GB processed                           |

## Repository Structure

This repository contains examples for:

1. `/datastreams` - Examples using Kinesis Data Streams

   - Producer/Consumer patterns
   - Shard management
   - Error handling

2. `/firehose` - Examples using Kinesis Firehose
   - Data transformation
   - S3 delivery
   - Error handling and retry logic
