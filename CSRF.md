# Jenkins CSRF Crumb Protection â€“ Summary

## What is a CSRF crumb?
- A **crumb** is a random token Jenkins issues to protect against **Cross-Site Request Forgery (CSRF)**.
- It ensures that only legitimate requests (from Jenkins UI or API clients) are accepted.

---

## Why crumbs are needed
- When using **cookie-based login (JSESSIONID)**:
  - Browsers automatically attach cookies to any request.
  - An attacker site (e.g., `evil.com`) could trick the browser into sending a POST to Jenkins.
  - Without a crumb, Jenkins would treat it as a valid request.
  - With a crumb check, Jenkins blocks the forged request.

- When using **API tokens (user:apitoken)**:
  - No cookies are auto-sent by the browser.
  - Attacker sites cannot steal or send tokens.
  - Since CSRF is not possible, Jenkins skips the crumb check.

---

## Key Takeaways
- **Cookie + Session Auth â†’ Crumb required** âœ…
- **API Token Auth â†’ Crumb not required** âœ…
- Crumbs protect against *CSRF*, not against authentication bypass.

---

## ASCII Diagram

```
=================== Cookie-based login (crumb required) ===================

   [User logs into Jenkins]
             |
   Browser stores JSESSIONID cookie
             |
   Evil.com sends hidden POST
             |
   Browser auto-sends cookie ---> [Jenkins]
                                   |
                            Crumb missing!
                                   |
                            [403 Forbidden âŒ]

-------------------------------------------------------------------------

=================== API token login (crumb not required) =================

   [Script/CLI client]
             |
   Sends request with Authorization: user:apitoken
             |
            [Jenkins]
             |
   No cookies â†’ no CSRF risk
             |
        [Request OK âœ…]
```

---

## Mermaid Diagram

```mermaid
flowchart TB

%% Cookie-based login flow
subgraph A["Cookie-based login (crumb required)"]
  U[User logs into Jenkins] --> B[Browser stores JSESSIONID cookie]
  B --> E[Evil.com sends hidden POST form]
  E --> C[Browser auto-sends cookie]
  C --> J1[Jenkins]
  J1 -->|Checks crumb| F[Crumb missing]
  F --> R1[403 Forbidden âŒ]
end

%% API token login flow
subgraph B["API token login (crumb not required)"]
  S[Script / CLI client] --> T[Authorization header user:apitoken]
  T --> J2[Jenkins]
  J2 -->|No cookies, no CSRF risk| R2[Request OK âœ…]
end

classDef blocked fill:#ffe6e6,stroke:#ff4d4d,color:#900;
classDef ok fill:#e6ffe6,stroke:#33cc33,color:#060;
class R1 blocked
class R2 ok
```
