# Queue retry study B

## Claim

Retry budgets prevent recovery traffic from starving new requests after a dependency becomes healthy.

## Evidence

In a local queue model capped at 10% retry traffic, new-request p95 latency stayed below 220 ms during recovery. With no retry budget it reached 940 ms while the retry backlog drained.

## Limitation

The model uses one service tier and a fixed arrival rate. It does not establish the correct budget for bursty or multi-tenant systems.
