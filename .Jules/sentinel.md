## 2026-04-03 - [Salted Hashing for Hard Focus Passphrases]
**Vulnerability:** Passphrases for Hard Focus mode were stored as unsalted SHA256 hashes in the local SQLite database. This made them susceptible to pre-computation (rainbow table) attacks.
**Learning:** Even for local-first applications, storing sensitive data like passphrases requires proper hashing techniques. A "placeholder" hash without a salt is a significant security gap if a malicious actor gains access to the local database file.
**Prevention:** Always use salted hashing for any stored passphrases. A unique salt per-session (even a simple UUID prefix) ensures that identical passphrases result in different hashes, effectively neutralizing common pre-computation attacks.
