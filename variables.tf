variable "name" {
  default     = null
  description = "Name of the guardrail."
}

variable "description" {
  default     = null
  description = "Description of the guardrail."
}

variable "blocked_input_messaging" {
  default     = "I can't help with that."
  description = "What the model returns when a prompt is blocked. Keep it short and non-specific — telling a caller exactly which filter fired tells them how to get around it."
}

variable "blocked_outputs_messaging" {
  default     = "I can't help with that."
  description = "What the model returns when a response is blocked."
}

variable "kms_key_arn" {
  default     = null
  description = "The ARN of a KMS key used to encrypt the guardrail. Left null, AWS uses a service-owned key."
}

variable "content_filters" {
  description = "Harmful content categories to filter, and how hard. Defaults to every category at HIGH, which is the point of a guardrail. PROMPT_ATTACK is input-only — AWS rejects any output strength other than NONE for it."
  type = list(object({
    type            = string
    input_strength  = optional(string, "HIGH")
    output_strength = optional(string, "HIGH")
  }))
  default = [
    { type = "SEXUAL" },
    { type = "VIOLENCE" },
    { type = "HATE" },
    { type = "INSULTS" },
    { type = "MISCONDUCT" },
    { type = "PROMPT_ATTACK", output_strength = "NONE" },
  ]

  validation {
    condition = alltrue([
      for f in var.content_filters :
      f.type != "PROMPT_ATTACK" || f.output_strength == "NONE"
    ])
    error_message = "PROMPT_ATTACK is evaluated on input only. Set its output_strength to NONE."
  }
}

variable "pii_entities" {
  description = "PII types to detect in prompts and responses, and what to do about them. 'BLOCK' refuses the request; 'ANONYMIZE' masks the value and lets it through."
  type = list(object({
    type   = string
    action = optional(string, "ANONYMIZE")
  }))
  default = []
}

variable "denied_topics" {
  description = "Subjects the model must refuse, each defined in a sentence or two. Definitions do the work here — a good definition matters far more than the examples."
  type = list(object({
    name       = string
    definition = string
    examples   = optional(list(string))
  }))
  default = []
}

variable "managed_word_lists" {
  default     = ["PROFANITY"]
  description = "AWS-managed word lists to block (currently 'PROFANITY'). Set to [] to disable."
}

variable "blocked_words" {
  default     = []
  description = "Literal words and phrases to block, on top of the managed lists."
}

variable "tags" {
  default     = null
  description = "A map of tags to assign to the guardrail."
}
