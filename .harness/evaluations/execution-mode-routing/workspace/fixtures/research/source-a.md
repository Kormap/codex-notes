# Queue retry study A

## Claim

Bounded exponential backoff reduces synchronized retries during short downstream outages.

## Evidence

In a deterministic simulation of 1,000 clients, a fixed one-second retry placed all second attempts in the same 100 ms bucket. Exponential backoff with deterministic test jitter spread second attempts across eight buckets and reduced the busiest bucket to 18% of clients.

## Limitation

The simulation excludes long outages, priority traffic and server-provided retry hints. It demonstrates retry dispersion, not production availability.
