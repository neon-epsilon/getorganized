# Frontend

- Check why updated timestamp is sometimes not recognized even though it was
  written just fine on the server. (Or get rid of timestamp polling mechanism
  altogether.)

- Stop retrying a failed AJAX request after timeout, instead reload.

- Also: Check, which failed AJAX requests should just be tried again, and which
  should just fail. (Right now, every AJAX request that fails is just tried
  again.)

- Only delete entries from shoppinglist that have been confirmed deleted by the
  server.

- Make sure that comments that are entered cannot exceed 40 characters.

- Make sure that shoppinglist is readable, even with long entries.

# Backend

- Enable setting a timezone (relevant for automatic generation of charts) in the charting-service container.

- Reimplement the API in something other than PHP. E.g. Rust with Axum.

- Maybe use PostgreSQL rather than MySQL/MariaDB, as the containerized version is much better.
