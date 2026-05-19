---
session_id: 7c4f1a2b
created: 2026-05-15T09:30Z
updated: 2026-05-15T11:45Z
status: blocked
branch: feature/payment-retry
worktree: /Users/jane/code/checkout-service
goal: Add idempotent retry to Stripe webhook handler so we stop double-charging on transient 5xx
next_action: Wire the new RetryQueue into webhook_handler.py:142 and add the dedupe-key check. Tests at tests/test_webhook_retry.py:18 should go green.
---

# Handoff: payment-retry

## Goal
Customers are getting double-charged when our Stripe webhook handler times out and Stripe retries. Need to add an idempotent retry layer keyed off the Stripe event ID so duplicate deliveries are no-ops. The dedupe table migration is already merged; the handler wiring is the remaining work.

## State
- Migration `0042_webhook_dedupe_table.sql` — merged, deployed to staging
- `RetryQueue` class in `lib/retry_queue.py` — written, unit-tested
- Webhook handler wiring — NOT done, this is the blocker
- Tests in `tests/test_webhook_retry.py` — written but failing (expected, until wiring lands)

## Next action
1. Open `webhook_handler.py:142` (the `def handle_stripe_event` entry point)
2. At the top of the function, add `if RetryQueue.seen(event.id): return 200`
3. Wrap the `process_payment(event)` call in `RetryQueue.record(event.id, ...)`
4. Run `pytest tests/test_webhook_retry.py -v` — should go green
5. Deploy to staging, replay yesterday's double-charge event from the Stripe dashboard

## DO NOT
- Add the dedupe check inside `process_payment()` — too late, you've already done the DB write
- Use the Stripe `idempotency_key` header — that's for outbound calls, doesn't apply here
- Skip the migration check (`SELECT 1 FROM webhook_dedupe LIMIT 1`) at handler startup — staging proved this catches misconfigured envs

## Key files
- /Users/jane/code/checkout-service/webhook_handler.py — handler entry point (line 142)
- /Users/jane/code/checkout-service/lib/retry_queue.py — the dedupe class
- /Users/jane/code/checkout-service/tests/test_webhook_retry.py — failing tests to make pass
- /Users/jane/code/checkout-service/migrations/0042_webhook_dedupe_table.sql — schema reference
- /Users/jane/code/checkout-service/docs/STRIPE_INTEGRATION.md — webhook contract

## Commands / URLs
- Staging webhook URL: https://staging.example.com/webhooks/stripe
- Stripe dashboard event replay: https://dashboard.stripe.com/test/events
- Deploy: `./infra/deploy.sh staging`
- Local test run: `pytest tests/test_webhook_retry.py -v`

## Open questions
- Do we backfill dedupe entries for the past 24h of webhook events, or just go-forward? (waiting on @priya)
