resource "random_uuid" "resource" {}

resource "aws_bedrock_guardrail" "resource" {
  name                      = coalesce(var.name, random_uuid.resource.id)
  description               = var.description
  blocked_input_messaging   = var.blocked_input_messaging
  blocked_outputs_messaging = var.blocked_outputs_messaging
  kms_key_arn               = var.kms_key_arn

  dynamic "content_policy_config" {
    for_each = length(var.content_filters) > 0 ? [1] : []

    content {
      dynamic "filters_config" {
        for_each = { for filter in var.content_filters : filter.type => filter }

        content {
          type            = filters_config.value.type
          input_strength  = filters_config.value.input_strength
          output_strength = filters_config.value.output_strength
        }
      }
    }
  }

  dynamic "sensitive_information_policy_config" {
    for_each = length(var.pii_entities) > 0 ? [1] : []

    content {
      dynamic "pii_entities_config" {
        for_each = { for entity in var.pii_entities : entity.type => entity }

        content {
          type   = pii_entities_config.value.type
          action = pii_entities_config.value.action
        }
      }
    }
  }

  dynamic "topic_policy_config" {
    for_each = length(var.denied_topics) > 0 ? [1] : []

    content {
      dynamic "topics_config" {
        for_each = { for topic in var.denied_topics : topic.name => topic }

        content {
          name       = topics_config.value.name
          definition = topics_config.value.definition
          examples   = topics_config.value.examples
          type       = "DENY"
        }
      }
    }
  }

  dynamic "word_policy_config" {
    for_each = length(var.managed_word_lists) > 0 || length(var.blocked_words) > 0 ? [1] : []

    content {
      dynamic "managed_word_lists_config" {
        for_each = toset(var.managed_word_lists)

        content {
          type = managed_word_lists_config.value
        }
      }

      dynamic "words_config" {
        for_each = toset(var.blocked_words)

        content {
          text = words_config.value
        }
      }
    }
  }

  tags = var.tags
}

output "id" {
  description = "The ID of the guardrail. Pass this and guardrail_version to an application calling InvokeModel."
  value       = aws_bedrock_guardrail.resource.guardrail_id
}

output "arn" {
  description = "The ARN of the guardrail."
  value       = aws_bedrock_guardrail.resource.guardrail_arn
}

output "name" {
  description = "The name of the guardrail."
  value       = aws_bedrock_guardrail.resource.name
}

output "version" {
  description = "The version of the guardrail. This is DRAFT until you publish a version — see the README, because pointing an application at DRAFT means it picks up edits immediately."
  value       = aws_bedrock_guardrail.resource.version
}
