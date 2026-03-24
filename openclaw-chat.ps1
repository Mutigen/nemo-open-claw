param(
  [Parameter(Mandatory = $true)]
  [string]$Message,

  [string]$SessionId = "local-session"
)

openclaw agent --agent main --local -m $Message --session-id $SessionId
