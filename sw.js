/* Lumi Catecismos — funciona sem internet.
   Arquivos do app: tenta a rede (até 3 s) e guarda a cópia; sem rede, usa a cópia guardada.
   Fontes do Google: usa a cópia guardada primeiro. Ao publicar mudança grande, troque a versão. */
const V='lumi-catecismos-v1';
const CORE=['/','/index.html','/app.js','/data.js','/data-maior.js','/data-conf.js','/manifest.webmanifest','/icon-192.png','/icon-512.png','/apple-touch-icon.png','/icon.svg'];
self.addEventListener('install',e=>{e.waitUntil(caches.open(V).then(c=>c.addAll(CORE)).then(()=>self.skipWaiting()))});
self.addEventListener('activate',e=>{e.waitUntil(caches.keys().then(ks=>Promise.all(ks.filter(k=>k!==V).map(k=>caches.delete(k)))).then(()=>self.clients.claim()))});
self.addEventListener('fetch',e=>{
  const r=e.request;if(r.method!=='GET')return;
  const u=new URL(r.url),same=u.origin===self.location.origin,font=/(^|\.)fonts\.(googleapis|gstatic)\.com$/.test(u.hostname);
  if(!same&&!font)return;
  e.respondWith(caches.open(V).then(async c=>{
    const key=same&&r.mode==='navigate'?'/index.html':r;
    const hit=await c.match(key,{ignoreSearch:same});
    if(font&&hit)return hit;
    const net=fetch(r).then(res=>{if(res&&(res.ok||res.type==='opaque'))c.put(key,res.clone());return res});
    const timeout=new Promise(ok=>setTimeout(()=>ok(null),hit?3000:15000));
    try{const res=await Promise.race([net,timeout]);if(res)return res}catch(err){}
    if(hit){e.waitUntil(net.catch(()=>{}));return hit}
    try{return await net}catch(err){return hit||Response.error()}
  }));
});
