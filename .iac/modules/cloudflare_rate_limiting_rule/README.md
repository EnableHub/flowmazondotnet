This Terraform module does the following:

- Puts in place a rate limiting rule on the zone (per-hostname rate limiting not possible on CloudFlare free plan)

## Usage Notes

### Assumptions

- This module assumes that a cloudflare zone already exists for the apex domain, a subdomain of which is going to be mapped to the ACA app via a CNAME record. The Zone ID of this zone is what is provided as value of input variable `cloudflare_zone_id`.

### Rate Limiting Rule

- On paid plans, you can create multiple rate limiting rules and different rate limiting rules for different hostnames in the zone.

  However, on the free plan, you can have just **one Rate Limiting Rule per zone** and this may only be created at the zone level.

  **To be able to work with the CloudFlare Free plan, this module creates a zone-level rate limiting rule. BEWARE THAT:**
  - the rule would apply to all CNAME and A records in the zone that are proxied through cloudflare.
  - On `terraform delete` the rule would be deleted. This may be problem if you have other DNS records on the zone that are proxied through Cloudflare for they would lose the protection of that rule also.

- **A complication with the zone-level rate limiting rule that this module creates, at least on the free plan, is that it may already exist** even if you can't see it in the Cloudflare Dashboard. This may be because you created it earlier in CloudFlare UI and then deleted it. If so, it would likely not have been been deleted and continues to exist, most likely with the name of **"default"** even if you had given it another name.

  **BEFORE USING THIS MODULE,** certainly if you are on the Free plan, **check if a zone level rate-limiting rule exists and delete it if it does, as follows** (deleting the rule in the UI would not work!). You can use the same `{api token}` that you have created to use this module:
  
  1. Run the following cURL to see if there is an existing ruleset with `phase = "http_ratelimit"`:

  ```bash
  curl -X GET "https://api.cloudflare.com/client/v4/zones/{zone_id}/rulesets" \
    -H "Authorization: Bearer {api_token}" \
    -H "Content-Type: application/json"
  ```
  2. In the list of rulesets that gets printed, take note of the `id` property of the ruleset with `phase = "http_ratelimit"`.

  3. Now run the following cURL to delete the rule with `phase = "http_ratelimit"` if you found one:

  ```bash
  curl -X DELETE  "https://api.cloudflare.com/client/v4/zones/{zone id}/rulesets/{id of the ruleset}"   -H "Authorization: Bearer {api_token}"
  ```
