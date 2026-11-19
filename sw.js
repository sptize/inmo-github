const C="inmo-v1",S=["./","style.css","common.js","logo.webp","hero.webp"];
self.addEventListener("install",e=>{e.waitUntil(caches.open(C).then(c=>c.addAll(S)).catch(()=>{}));self.skipWaiting()});
self.addEventListener("activate",e=>e.waitUntil(clients.claim()));
self.addEventListener("fetch",e=>{const u=new URL(e.request.url);if(e.request.method!="GET"||u.origin!=location.origin)return;
e.respondWith(fetch(e.request).then(r=>{const k=r.clone();caches.open(C).then(c=>c.put(e.request,k));return r}).catch(()=>caches.match(e.request)))});
self.addEventListener("push",e=>{let d={title:"InMo",body:"Nueva propiedad pendiente"};try{d=e.data.json()}catch(x){}
e.waitUntil(self.registration.showNotification(d.title,{body:d.body,icon:"icon-192.png",badge:"icon-192.png",vibrate:[200,100,200],data:{url:"admin.html"}}))});
self.addEventListener("notificationclick",e=>{e.notification.close();e.waitUntil(clients.matchAll({type:"window",includeUncontrolled:true}).then(l=>{for(const c of l)if(c.url.includes("admin.html")&&"focus"in c)return c.focus();return clients.openWindow("admin.html")}))});
