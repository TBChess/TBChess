'use strict';

/* eslint-env browser, serviceworker */

self.addEventListener('install', () => {
	self.skipWaiting();
});

self.addEventListener('push', function(event) {
	var notificationTitle = 'TBChess';

	const notificationOptions = {
		body: '',
		icon: './icons/192.png',
		// badge: './images/badge-72x72.png',
		data: {
			path: '',
		},
	};

	if (event.data) {
		const payload = event.data.text();
        try{
            var j = JSON.parse(payload); 
            notificationTitle = j.title;
            notificationOptions.body = j.message;
            notificationOptions.data.path = j.path;
            
            event.waitUntil(
                self.registration.showNotification(
                    notificationTitle,
                    notificationOptions,
                ),
            );
        }catch(e){
            console.warning(e);
        }
	}
});

self.addEventListener('notificationclick', function(event) {
	event.notification.close();

	let clickResponsePromise = Promise.resolve();
	if (event.notification.data && event.notification.data.path) {
        clickResponsePromise = (async () => {
            const allClients = await clients.matchAll({
                includeUncontrolled: true,
            });

            let appClient;

            for (const client of allClients) {
                const url = new URL(client.url);

                if (url.hash === `#/${event.notification.data.path}` || url.path === event.notification.data.path) {
                    // Excellent, let's use it!
                    client.focus();
                    appClient = client;
                    break;
                }
            }

            // If we didn't find an existing window,
            // open a new one:
            return appClient ??= await clients.openWindow(self.registration.scope + "#/" + event.notification.data.path);
        })();
	}

	event.waitUntil(clickResponsePromise);
});