// Teste ponta a ponta: o "computador" abre a sala; o "celular" (este script) envia a aula e passa slides.
const { chromium } = require('playwright');
const fs = require('fs');
const U = 'https://tohphjpibyfikrmgswhk.supabase.co';
const KEY = fs.readFileSync(__dirname + '/../index.html', 'utf8').match(/var KEY = '([^']+)'/)[1];
const H = { apikey: KEY, Authorization: 'Bearer ' + KEY };
const log = [];
const say = (...a) => { const t = a.join(' '); console.log(t); log.push(t); };
(async () => {
  const b = await chromium.launch();
  const pg = await b.newPage({ viewport: { width: 1280, height: 720 } });
  pg.on('pageerror', e => say('pageerror', e.message));
  await pg.goto('http://127.0.0.1:8765/aula/', { waitUntil: 'load' });
  await pg.waitForFunction(() => /\d{3} \d{3}/.test(document.getElementById('code').textContent), null, { timeout: 20000 });
  const code = (await pg.textContent('#code')).replace(/\s/g, '');
  say('sala', code);
  await pg.screenshot({ path: 'out/lobby.png' });
  await pg.waitForTimeout(2500);

  const info = async () => (await (await fetch(U + '/rest/v1/rpc/sala_info', { method: 'POST', headers: { ...H, 'Content-Type': 'application/json' }, body: JSON.stringify({ p_code: code }) })).json())[0];
  say('info', JSON.stringify(await info()));

  // empacota a aula de exemplo dentro da página (mesmo código do app)
  const aula = JSON.parse(fs.readFileSync(__dirname + '/exemplo.json'));
  const img = 'data:image/jpeg;base64,' + fs.readFileSync(__dirname + '/a.jpg').toString('base64');
  const b64 = await pg.evaluate(([a, i]) => AulaKit.pack(a, { 'a.jpg': i }), [aula, img]);
  const path = `salas/${code}/teste-${Date.now()}.vvaula`;
  let r = await fetch(U + '/storage/v1/object/aulas/' + path, { method: 'POST', headers: { ...H, 'Content-Type': 'application/zip' }, body: Buffer.from(b64, 'base64') });
  say('upload', r.status, await r.text());
  r = await fetch(U + '/rest/v1/rpc/sala_arquivo', { method: 'POST', headers: { ...H, 'Content-Type': 'application/json' }, body: JSON.stringify({ p_code: code, p_arquivo: path }) });
  say('sala_arquivo', r.status, await r.text());
  const send = async (payload) => {
    const res = await fetch(U + '/realtime/v1/api/broadcast', { method: 'POST', headers: { ...H, 'Content-Type': 'application/json' }, body: JSON.stringify({ messages: [{ topic: 'sala-' + code, event: 'cmd', payload }] }) });
    say('broadcast', JSON.stringify(payload), res.status);
  };
  await send({ t: 'load', file: path, f: 0 });
  await pg.waitForFunction(() => document.getElementById('show').style.display === 'flex', null, { timeout: 20000 }).catch(() => say('ERRO: aula não carregou'));
  await pg.waitForTimeout(1500);
  await pg.screenshot({ path: 'out/s0.png' });
  await send({ t: 'go', f: 2 });
  await pg.waitForTimeout(1500);
  say('quadro no PC', await pg.evaluate(() => window.__aula.cur()));
  await pg.screenshot({ path: 'out/s2.png' });
  await pg.keyboard.press('ArrowRight');
  await pg.waitForTimeout(2500);
  say('info depois da seta', JSON.stringify(await info()));
  const up = await fetch(U + '/storage/v1/object/aulas/outra/x.vvaula', { method: 'POST', headers: { ...H, 'Content-Type': 'application/zip' }, body: 'x' });
  say('upload fora da pasta (deve falhar)', up.status);
  const lim = await fetch(U + '/functions/v1/limpar', { method: 'POST', headers: { ...H, 'Content-Type': 'application/json' }, body: '{}' });
  say('limpar', lim.status, await lim.text());
  await b.close();
  fs.writeFileSync('out/smoke.txt', log.join('\n') + '\n');
})().catch(e => { say('FALHOU', e.stack); fs.writeFileSync('out/smoke.txt', log.join('\n') + '\n'); process.exit(1); });
