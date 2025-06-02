# Amazon Kendra Testing

Amazon Kendra is an intelligent enterprise search service that helps you search through unstructured data using natural language processing. It can search through documents, FAQs, websites, and databases, providing highly relevant results and suggested answers.

## Features

- Natural language queries
- Document ranking based on importance
- Contextual answers
- Support for multiple data sources
- FAQ matching
- Custom synonyms and tuning

## Cost Considerations ⚠️

**Important:** Kendra has a **minimum 24-hour billing period** when you create an index.

### Developer Edition (Recommended for testing)

- Index: $81/month ($2.64 for minimum 24h)
- Storage: First 100 documents free
- Queries: First 0.05 QPS (queries per second) included

### Enterprise Edition

- Index: $810/month ($26.40 for minimum 24h)
- Higher capacity and customization options
- Not recommended for testing

## Quick Setup

1. Create Kendra Index (AWS Console)

   ```bash
   # Will take 15-30 minutes to create
   AWS Console -> Amazon Kendra -> Create Index -> Developer Edition
   ```

2. Add Data Sources

   - Documents (PDF, HTML, Text)
   - FAQs
   - Websites
   - Databases

3. Test Search

   ```python
   import boto3

   kendra = boto3.client('kendra')
   response = kendra.query(
       IndexId='your-index-id',
       QueryText='your search query'
   )
   ```

## Best Practices

- Start with small dataset for testing
- Use Developer Edition for POCs
- Remember to delete the index after testing (but you'll still be charged for 24h)
- Test with various query types (keywords, natural language, specific phrases)

## Limitations

- Index creation: 15-30 minutes
- Document indexing: Few minutes per document
- API Quotas: Check AWS documentation for current limits
- Supported file types: Check AWS documentation for updated list
