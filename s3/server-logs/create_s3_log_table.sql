CREATE EXTERNAL TABLE IF NOT EXISTS s3_logs.s3_server_logs (
  bucket_owner          string,
  bucket                string,
  time                  string,
  remote_ip             string,
  requester             string,
  request_id            string,
  operation             string,
  key                   string,
  request_uri           string,
  http_status           string,
  error_code            string,
  bytes_sent            bigint,
  object_size           bigint,
  total_time            bigint,
  turnaround_time       bigint,
  referrer              string,
  user_agent            string,
  version_id            string,
  host_id               string,
  signature_version     string,
  cipher_suite          string,
  authentication_type   string,
  host_header           string,
  tls_version           string,
  access_point_arn      string,
  acl_required          string
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.RegexSerDe'
WITH SERDEPROPERTIES (
  'input.regex' = '(\\S+) (\\S+) \\[([^\\]]+)\\] (\\S+) (\\S+) (\\S+) (\\S+) (\\S+) \"([^\"]*)\" (\\S+) (\\S+) (\\S+) (\\S+) (\\S+) (\\S+) \"([^\"]*)\" \"([^\"]*)\" (\\S*) (\\S*) (\\S*) (\\S*) (\\S*) (\\S*) (\\S*) (\\S*) (\\S*)'
)
STORED AS TEXTFILE
LOCATION 's3://server-logs-destination-bucket-0988/logs/'
TBLPROPERTIES (
  'skip.header.line.count' = '0'
);
