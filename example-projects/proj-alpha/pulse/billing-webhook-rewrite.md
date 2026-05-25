---
id: billing-webhook-rewrite
project: billing-webhook-rewrite
status: blocked
health: red
completion: 30
priority: p1
last_touched: 2026-05-18
paths:
  - src/billing/webhooks/**
  - tests/billing/webhooks/**
owner: human
---

# Billing Webhook Rewrite

## Last Stop
Got the new handler skeleton in place and migrated `invoice.paid` and
`invoice.payment_failed`. Paused when finance flagged that they're
evaluating switching to a Stripe-plus-Adyen split for EU customers. If
that lands, half of the rewrite assumptions go away.

## Next Actions
Nothing until the vendor decision lands.

## What Finishing Looks Like
- [x] `invoice.paid` migrated
- [x] `invoice.payment_failed` migrated
- [ ] `subscription.*` events migrated
- [ ] Old handler deleted
- [ ] Idempotency keys verified under chaos test

## Blockers
**Vendor decision: Stripe-only vs Stripe + Adyen for EU billing.**
- Owner: Marcus (finance) + Priya (eng director)
- Expected: end of May per the last status sync
- Escalation path: if no decision by June 5, surface this in eng leadership weekly

## Notes
The 30% completion number is a lie in one direction: the code that's
written is solid and tested. It's a lie in the other direction: that code
may be worthless depending on the decision.
