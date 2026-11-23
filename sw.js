/* Verteilerplanung: immer zuerst die neueste Version aus dem Netz (ohne Browser-Cache), bei fehlendem Netz die zuletzt geladene */
const C='vp-cache-v2';
self.addEventListener('install',e=>self.skipWaiting());
self.addEventListener('activate',e=>e.waitUntil(caches.keys().then(K=>Promise.all(K.filter(k=>k!==C).map(k=>caches.delete(k)))).then(()=>self.clients.claim())));
self.addEventListener('fetch',e=>{
  const r=e.request;if(r.method!=='GET'||new URL(r.url).origin!==location.origin)return;
  const fresh=r.mode==='navigate'||/\/(index\.html|version\.json)?(\?|$)/.test(new URL(r.url).pathname+new URL(r.url).search);
  e.respondWith(fetch(fresh?new Request(r,{cache:'no-store'}):r).then(res=>{const cp=res.clone();caches.open(C).then(c=>c.put(r,cp)).catch(()=>{});return res}).catch(()=>caches.match(r,{ignoreSearch:true})));
});
