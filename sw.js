/* Verso Vivo Catecismos — funciona sem internet.
   Arquivos do app: tenta a rede (até 3 s) e guarda a cópia; sem rede, usa a cópia guardada.
   Fontes e imagens vêm do próprio site (nada de Google Fonts). Ao publicar mudança grande, troque a versão. */
const V='verso-vivo-catecismos-v2';
const IMG=['dica','dica-pisca','dormindo','festa','lendo','lendo-pisca','oi','oi-pisca','pensando','pensando-pisca','rosto','sarca'].map(n=>'/img/nine-'+n+'.webp');
const CORE=['/','/index.html','/app.js','/data.js','/data-maior.js','/data-conf.js','/manifest.webmanifest','/icon-192.png','/icon-512.png','/apple-touch-icon.png',
  '/fonts/Cinzel-Variable.woff','/fonts/Lora-Variable.woff','/fonts/Lora-Italic-Variable.woff','/img/mundo1.webp','/img/mundo2.webp','/img/mundo3.webp',...IMG];
self.addEventListener('install',e=>{e.waitUntil(caches.open(V).then(c=>c.addAll(CORE)).then(()=>self.skipWaiting()))});
self.addEventListener('activate',e=>{e.waitUntil(caches.keys().then(ks=>Promise.all(ks.filter(k=>k!==V).map(k=>caches.delete(k)))).then(()=>self.clients.claim()))});
self.addEventListener('fetch',e=>{
  const r=e.request;if(r.method!=='GET')return;
  const u=new URL(r.url);if(u.origin!==self.location.origin)return;
  const asset=/^\/(fonts|img)\//.test(u.pathname);
  e.respondWith(caches.open(V).then(async c=>{
    const key=r.mode==='navigate'?'/index.html':r;
    const hit=await c.match(key,{ignoreSearch:true});
    if(asset&&hit)return hit;
    const net=fetch(r).then(res=>{if(res&&res.ok)c.put(key,res.clone());return res});
    const timeout=new Promise(ok=>setTimeout(()=>ok(null),hit?3000:15000));
    try{const res=await Promise.race([net,timeout]);if(res)return res}catch(err){}
    if(hit){e.waitUntil(net.catch(()=>{}));return hit}
    try{return await net}catch(err){return hit||Response.error()}
  }));
});
