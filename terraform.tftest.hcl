mock_provider "aws" {}

run "prompt_attack_with_an_output_strength_is_rejected" {
  command = plan

  variables {
    content_filters = [
      { type = "PROMPT_ATTACK", output_strength = "HIGH" },
    ]
  }

  expect_failures = [var.content_filters]
}

run "defaults_filter_everything_at_high" {
  command = apply

  assert {
    condition     = aws_bedrock_guardrail.resource.name == random_uuid.resource.id
    error_message = "With no name given, the guardrail should use the generated random_uuid."
  }

  assert {
    condition     = length(aws_bedrock_guardrail.resource.content_policy_config[0].filters_config) == 6
    error_message = "All six harmful content categories should be filtered by default."
  }

  assert {
    condition = alltrue([
      for f in aws_bedrock_guardrail.resource.content_policy_config[0].filters_config :
      f.input_strength == "HIGH"
    ])
    error_message = "Every category should be filtered at HIGH on input by default — a guardrail set to LOW is decoration."
  }

  assert {
    condition = anytrue([
      for f in aws_bedrock_guardrail.resource.content_policy_config[0].filters_config :
      f.type == "PROMPT_ATTACK" && f.output_strength == "NONE"
    ])
    error_message = "PROMPT_ATTACK is input-only and its output strength must be NONE."
  }

  assert {
    condition     = length(aws_bedrock_guardrail.resource.word_policy_config[0].managed_word_lists_config) == 1
    error_message = "The managed profanity list should be on by default."
  }

  assert {
    condition     = length(aws_bedrock_guardrail.resource.sensitive_information_policy_config) == 0
    error_message = "No PII policy should be emitted when no entities are configured."
  }

  assert {
    condition     = length(aws_bedrock_guardrail.resource.topic_policy_config) == 0
    error_message = "No topic policy should be emitted when no topics are denied."
  }
}

run "pii_entities_default_to_anonymise" {
  command = plan

  variables {
    pii_entities = [
      { type = "EMAIL" },
      { type = "US_SOCIAL_SECURITY_NUMBER", action = "BLOCK" },
    ]
  }

  assert {
    condition     = length(aws_bedrock_guardrail.resource.sensitive_information_policy_config[0].pii_entities_config) == 2
    error_message = "Both PII entities should be configured."
  }

  assert {
    condition = anytrue([
      for e in aws_bedrock_guardrail.resource.sensitive_information_policy_config[0].pii_entities_config :
      e.type == "EMAIL" && e.action == "ANONYMIZE"
    ])
    error_message = "An entity with no action should default to ANONYMIZE rather than BLOCK."
  }
}

run "denied_topics_are_always_deny_type" {
  command = plan

  variables {
    denied_topics = [
      {
        name       = "legal-advice"
        definition = "Any request for legal advice, interpretation of law, or guidance on a specific legal matter."
        examples   = ["Should I sue?"]
      },
    ]
  }

  assert {
    condition     = aws_bedrock_guardrail.resource.topic_policy_config[0].topics_config[0].type == "DENY"
    error_message = "Denied topics should always be configured with type DENY."
  }
}

run "word_policy_is_omitted_when_fully_disabled" {
  command = plan

  variables {
    managed_word_lists = []
    blocked_words      = []
  }

  assert {
    condition     = length(aws_bedrock_guardrail.resource.word_policy_config) == 0
    error_message = "No word policy block should be emitted when both lists are empty."
  }
}

run "blocked_words_are_passed_through" {
  command = plan

  variables {
    blocked_words = ["competitorname", "internal-codename"]
  }

  assert {
    condition     = length(aws_bedrock_guardrail.resource.word_policy_config[0].words_config) == 2
    error_message = "Literal blocked words should be passed through."
  }
}
