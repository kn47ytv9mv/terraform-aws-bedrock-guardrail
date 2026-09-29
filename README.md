# terraform-aws-bedrock-guardrail

Terraform module for a Bedrock guardrail, the policy layer between a
caller and a model that refuses what the model would otherwise answer.

## Cost

Guardrails are billed per text unit evaluated, and each policy type is
billed separately against the same request. Content filters, denied
topics, PII detection and word filters are four independent charges, and
each applies to both the prompt and the response.

The practical consequence is that enabling every policy multiplies the
per-request cost. Enable the policies the threat model justifies rather
than all of them. There is no standing charge: a guardrail nobody calls
costs nothing. See AWS's
[Bedrock pricing](https://aws.amazon.com/bedrock/pricing/) page for
current rates.

## Design

Defaults are strict. Every harmful content category is filtered at `HIGH`,
prompt-attack detection is on, and the managed profanity list is enabled.
A guardrail configured at `LOW` is decoration, so a looser setting should
be a decision rather than something inherited.

### Prompt attack is evaluated on input only

AWS rejects any output strength other than `NONE` for `PROMPT_ATTACK`. The
module validates this at plan time rather than letting the apply fail.

### Versions

`version` reads `DRAFT` until a version is published. An application
pointed at `DRAFT` picks up every edit the moment it is applied, which is
convenient while developing and wrong in production. Publish a version and
pin to it.

### Writing the policies

Definitions carry the weight in `denied_topics`. The model reasons from
the definition and the examples only nudge it, so a vague definition
produces a guardrail that fires unpredictably.

The blocked messaging is deliberately uninformative. Naming the filter
that refused a request tells the caller how to work around it.

`ANONYMIZE` against `BLOCK` for a PII entity is a product decision rather
than a security one. Anonymising lets the conversation continue with the
value masked; blocking refuses outright. The default is `ANONYMIZE`,
because refusing an entire request over an email address is usually the
wrong trade.

## Usage

```hcl
module "guardrail" {
  source = "kn47ytv9mv/bedrock-guardrail/aws"

  name        = "example"
  description = "Default guardrail for the support assistant."
}
```

Or directly from this repository:

```hcl
module "guardrail" {
  source = "github.com/kn47ytv9mv/terraform-aws-bedrock-guardrail"

  name = "example"
}
```

With PII masking, a denied topic and a blocked term:

```hcl
module "guardrail" {
  source = "kn47ytv9mv/bedrock-guardrail/aws"

  name = "example"

  pii_entities = [
    { type = "EMAIL" },
    { type = "PHONE" },
    { type = "US_SOCIAL_SECURITY_NUMBER", action = "BLOCK" },
  ]

  denied_topics = [
    {
      name       = "legal-advice"
      definition = "Any request for legal advice, interpretation of law, or guidance on how to act in a specific legal matter."
      examples   = ["Should I sue them?", "Is this contract enforceable?"]
    },
  ]

  blocked_words = ["internal-codename"]
}
```

## Requirements

| Name | Version |
|---|---|
| terraform | >= 1.3 |
| aws | ~> 6.61 |
| random | ~> 3.9 |

## Providers

| Name | Version |
|---|---|
| aws | ~> 6.61 |
| random | ~> 3.9 |

## Inputs

| Name | Description | Default | Required |
|---|---|---|---|
| name | Name of the guardrail. | `null` | no |
| description | Description of the guardrail. | `null` | no |
| blocked_input_messaging | What the model returns when a prompt is blocked. | `"I can't help with that."` | no |
| blocked_outputs_messaging | What the model returns when a response is blocked. | `"I can't help with that."` | no |
| kms_key_arn | The ARN of a KMS key used to encrypt the guardrail. | `null` | no |
| content_filters | Harmful content categories to filter, and how hard. | all six at `HIGH` | no |
| pii_entities | PII types to detect, and whether to block or anonymise. | `[]` | no |
| denied_topics | Subjects the model must refuse, each with a definition. | `[]` | no |
| managed_word_lists | AWS-managed word lists to block. | `["PROFANITY"]` | no |
| blocked_words | Literal words and phrases to block. | `[]` | no |
| tags | A map of tags to assign to the guardrail. | `null` | no |

## Outputs

| Name | Description |
|---|---|
| id | The ID of the guardrail. Pass with `version` to `InvokeModel`. |
| arn | The ARN of the guardrail. |
| name | The name of the guardrail. |
| version | The version of the guardrail, `DRAFT` until one is published. |

## License

MIT — see [LICENSE.md](LICENSE.md).
