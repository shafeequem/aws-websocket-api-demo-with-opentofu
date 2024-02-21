// Service worker script (sw.js)
self.addEventListener('push', function(event) {
  const options = {
    body: event.data.text(),
  };

  event.waitUntil(
    self.registration.showNotification('Your App Name', options)
  );
});
