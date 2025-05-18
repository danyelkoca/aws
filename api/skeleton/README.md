# AWS EC2 CLI Skeleton Example

This guide demonstrates how to use the AWS CLI to generate, modify, and execute input files for launching EC2 instances. It also includes troubleshooting and cleanup steps.

---

## Generate CLI Skeleton

The `--generate-cli-skeleton` flag produces a JSON template for the CLI command input. This is useful for editing or scripting complex commands. It **does not execute** the command.

```bash
# Generates a full JSON input template with placeholder values.
# Note: provided arguments like --image-id are ignored in the output.
aws ec2 run-instances \
    --image-id <your-ami-id> \
    --instance-type t2.micro \
    --generate-cli-skeleton \
    --output json > skeleton.json
```

### If you want a filled template with your actual input values:

```bash
aws ec2 run-instances \
    --image-id <your-ami-id> \
    --instance-type t2.micro \
    --generate-cli-skeleton input
```

---

## Convert JSON Skeleton to YAML

Use `yq` to convert the generated JSON file into YAML for easier readability:

```bash
yq -pjson -oy skeleton.json > skeleton.yaml
```

---

## Load YAML Input File

You can execute an EC2 launch using the YAML input:

```bash
aws ec2 run-instances \
    --cli-input-yaml file://skeleton.yaml
```

### Possible Error

```text
Parameter validation failed:
Invalid value for parameter ElasticInferenceAccelerators[0].Count, value: 0, valid min value: 1
```

To fix this, remove or comment out the `ElasticInferenceAccelerators` section in your YAML file.

If you proceed further, you may hit:

```text
An error occurred (UnknownParameter) when calling the RunInstances operation: The parameter SpreadDomain is not recognized
```

This means the generated skeleton may contain invalid or outdated fields. It's **not reliable** to use `--generate-cli-skeleton` output directly. You should remove unused or invalid parameters.

---

## Minimal Valid Input Example

Instead of modifying a complex skeleton, you can start with a minimal valid YAML file:

```yaml
ImageId: <your-ami-id>
InstanceType: t2.micro
```

Save this as `skeleton_new.yaml` and run:

```bash
aws ec2 run-instances \
    --cli-input-yaml file://skeleton_new.yaml
```

---

## Terminate an EC2 Instance

To clean up your resources, terminate the EC2 instance by replacing `<instance-id>` with your actual instance ID:

```bash
aws ec2 terminate-instances --instance-ids <instance-id>
```

### Sample Output

```json
{
  "TerminatingInstances": [
    {
      "InstanceId": "<instance-id>",
      "CurrentState": {
        "Code": 32,
        "Name": "shutting-down"
      },
      "PreviousState": {
        "Code": 16,
        "Name": "running"
      }
    }
  ]
}
```
