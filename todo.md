# Frontend

- Check why updated timestamp is not recognized as updated timestamp.

- Stop retrying a failed AJAX request after timeout, instead reload.

- Also: Check, which failed AJAX requests should just be tried again, and which
  should just fail. (Right now, every AJAX request that fails is just tried
  again.)

- Only delete entries from shoppinglist that have been confirmed deleted by the
  server.

- Make sure that comments that are entered cannot exceed 40 characters.

- Make sure that shoppinglist is readable, even with long entries.

# Backend

- Turn charting service container into web server rather than loose collection
  of scripts in a container.