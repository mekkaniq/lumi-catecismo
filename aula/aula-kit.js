/* Verso Vivo · Aulas
 * Peças comuns ao app (dentro de uma WebView) e ao site de apresentação:
 *  - temas e "quadros" (um slide com resposta vira dois quadros: pergunta e resposta)
 *  - gerar PowerPoint (.pptx) com PptxGenJS
 *  - ler um PowerPoint e trazer texto e imagens de cada slide
 *  - empacotar e abrir o arquivo da aula (.vvaula = zip com aula.json + media/)
 */
(function (root) {
  'use strict';

  var THEMES = {
    verde:  { name: 'Verde',       bg: '0E170A', bg2: '3D5A2A', fg: 'FBF1D8', muted: 'CFC09A', accent: 'F0CD7E', card: '1F2C16', ok: '9FD08A' },
    vinho:  { name: 'Vinho',       bg: '1C0A0C', bg2: '7A2F38', fg: 'FBF1D8', muted: 'E3C7B8', accent: 'F0CD7E', card: '2E1316', ok: '9FD08A' },
    azul:   { name: 'Azul',        bg: '071720', bg2: '245A74', fg: 'FBF1D8', muted: 'BFD6DE', accent: 'F0CD7E', card: '10293A', ok: '9FD08A' },
    claro:  { name: 'Pergaminho',  bg: 'F7EDD3', bg2: 'EAD9AE', fg: '2A1D0C', muted: '6D5C3B', accent: '9A6B12', card: 'FFFAEC', ok: '2F7D4A' }
  };

  var KINDS = {
    titulo: 'Título', catecismo: 'Catecismo', biblia: 'Texto bíblico', topicos: 'Tópicos',
    imagem: 'Imagem', discussao: 'Para conversar', quiz: 'Quiz', pagina: 'Página importada'
  };

  function theme(aula) { return THEMES[(aula && aula.theme) || 'verde'] || THEMES.verde; }

  /** Slides com resposta escondida rendem dois quadros. */
  function hasReveal(s) { return s.kind === 'catecismo' || s.kind === 'quiz'; }
  function frames(aula) {
    var out = [];
    (aula.slides || []).forEach(function (s, i) {
      out.push({ i: i, step: 0 });
      if (hasReveal(s)) out.push({ i: i, step: 1 });
    });
    return out;
  }

  /** Tamanho de letra que cabe, pelo tamanho do texto (em pontos, slide de 13,33 x 7,5 pol.). */
  function fit(text, big, small, longAt) {
    var n = (text || '').length;
    if (n <= longAt * 0.35) return big;
    if (n >= longAt) return small;
    var t = (n - longAt * 0.35) / (longAt * 0.65);
    return Math.round(big - (big - small) * t);
  }

  var LETTERS = ['A', 'B', 'C', 'D', 'E', 'F'];

  // ---------- PowerPoint ----------

  /**
   * aula: objeto da aula; media: { "nome.jpg": "data:image/jpeg;base64,..." }
   * Devolve uma Promise com o .pptx em base64.
   */
  /** Fundo com brilho suave (como o do app), desenhado num canvas. */
  function backdrop(T, w, h) {
    var doc = root.document;
    if (!doc) return null;
    var c = doc.createElement('canvas');
    c.width = w || 1600; c.height = h || 900;
    var g = c.getContext('2d');
    var hex = function (x, a) { var n = parseInt(x, 16); return 'rgba(' + (n >> 16 & 255) + ',' + (n >> 8 & 255) + ',' + (n & 255) + ',' + a + ')'; };
    g.fillStyle = '#' + T.bg; g.fillRect(0, 0, c.width, c.height);
    var r = g.createRadialGradient(c.width * 0.72, c.height * 0.18, 0, c.width * 0.72, c.height * 0.18, c.width * 0.75);
    r.addColorStop(0, hex(T.bg2, 0.95)); r.addColorStop(0.55, hex(T.bg2, 0.35)); r.addColorStop(1, hex(T.bg2, 0));
    g.fillStyle = r; g.fillRect(0, 0, c.width, c.height);
    var gold = g.createRadialGradient(c.width * 0.8, c.height * 0.1, 0, c.width * 0.8, c.height * 0.1, c.width * 0.32);
    gold.addColorStop(0, hex(T.accent, T === THEMES.claro ? 0.18 : 0.22)); gold.addColorStop(1, hex(T.accent, 0));
    g.fillStyle = gold; g.fillRect(0, 0, c.width, c.height);
    var v = g.createLinearGradient(0, c.height * 0.55, 0, c.height);
    v.addColorStop(0, hex(T.bg, 0)); v.addColorStop(1, hex(T.bg, 0.55));
    g.fillStyle = v; g.fillRect(0, 0, c.width, c.height);
    return c.toDataURL('image/jpeg', 0.9);
  }

  function dims(src) {
    return new Promise(function (ok) {
      if (!root.Image) return ok({ w: 4, h: 3 });
      var im = new root.Image();
      im.onload = function () { ok({ w: im.naturalWidth || 4, h: im.naturalHeight || 3 }); };
      im.onerror = function () { ok({ w: 4, h: 3 }); };
      im.src = src;
    });
  }

  function contain(d, x, y, w, h) {
    var k = Math.min(w / d.w, h / d.h);
    var cw = d.w * k, ch = d.h * k;
    return { x: x + (w - cw) / 2, y: y + (h - ch) / 2, w: cw, h: ch };
  }

  function toPptx(aula, media, PptxGen) {
    var keys = Object.keys(media || {});
    return Promise.all(keys.map(function (k) { return dims(media[k]); })).then(function (ds) {
      var sizes = {};
      keys.forEach(function (k, i) { sizes[k] = ds[i]; });
      return buildPptx(aula, media, sizes, PptxGen);
    });
  }

  function buildPptx(aula, media, sizes, PptxGen) {
    PptxGen = PptxGen || root.PptxGenJS;
    var p = new PptxGen();
    p.layout = 'LAYOUT_WIDE';
    p.title = aula.title || 'Aula';
    p.company = 'Verso Vivo';
    var T = theme(aula);
    var W = 13.333, H = 7.5, M = 0.7;
    var serif = 'Georgia', sans = 'Calibri';
    var all = frames(aula);
    var bg = backdrop(T);

    all.forEach(function (fr, k) {
      var s = aula.slides[fr.i];
      var sl = p.addSlide();
      sl.background = bg ? { data: bg } : { color: T.bg };
      var pic = function (name, x, y, w, h) {
        if (!name || !media || !media[name]) return;
        var b = contain(sizes[name] || { w: 4, h: 3 }, x, y, w, h);
        sl.addImage({ data: media[name], x: b.x, y: b.y, w: b.w, h: b.h });
      };
      sl.addShape(p.ShapeType.rect, { x: M, y: H - 0.55, w: W - 2 * M, h: 0.02, fill: { color: T.accent, transparency: 40 }, line: { type: 'none' } });
      sl.addText(aula.title || '', { x: M, y: H - 0.5, w: 8, h: 0.35, fontFace: sans, fontSize: 11, color: T.muted });
      sl.addText(String(k + 1) + ' / ' + all.length, { x: W - M - 2, y: H - 0.5, w: 2, h: 0.35, fontFace: sans, fontSize: 11, color: T.muted, align: 'right' });
      if (s.notes) sl.addNotes(s.notes);

      var label = function (t, y) {
        sl.addText((t || '').toUpperCase(), { x: M, y: y || 0.5, w: W - 2 * M, h: 0.4, fontFace: sans, fontSize: 14, bold: true, color: T.accent, charSpacing: 3 });
      };

      switch (s.kind) {
        case 'titulo':
          if (s.text) label(s.text, 2.0);
          sl.addText(s.title || '', { x: M, y: 2.45, w: W - 2 * M, h: 2.2, fontFace: serif, bold: true, fontSize: fit(s.title, 54, 34, 90), color: T.fg, valign: 'top' });
          if (s.items && s.items[0]) sl.addText(s.items[0], { x: M, y: 4.8, w: W - 2 * M, h: 0.8, fontFace: sans, fontSize: 22, color: T.muted });
          break;

        case 'catecismo': {
          label(s.label || 'Catecismo', 0.5);
          var qa = fr.step === 0;
          sl.addText(s.q || '', { x: M, y: 1.0, w: W - 2 * M, h: qa ? 4.6 : 1.7, fontFace: serif, bold: true, fontSize: qa ? fit(s.q, 48, 32, 160) : fit(s.q, 30, 22, 160), color: T.fg, valign: qa ? 'middle' : 'top' });
          if (!qa) {
            sl.addShape(p.ShapeType.roundRect, { x: M, y: 2.85, w: W - 2 * M, h: 3.55, rectRadius: 0.15, fill: { color: T.card }, line: { color: T.accent, transparency: 60, width: 1 } });
            sl.addText(s.a || '', { x: M + 0.3, y: 2.95, w: W - 2 * M - 0.6, h: 3.0, fontFace: serif, fontSize: fit(s.a, 34, 16, 900), color: T.fg, valign: 'top', paraSpaceAfter: 4 });
            if (s.r) sl.addText(s.r, { x: M + 0.3, y: 5.95, w: W - 2 * M - 0.6, h: 0.4, fontFace: sans, fontSize: 11, color: T.muted });
          }
          break;
        }

        case 'biblia':
          sl.addText('“' + (s.text || '') + '”', { x: M + 0.4, y: 0.8, w: W - 2 * M - 0.8, h: 4.6, fontFace: serif, italic: true, fontSize: fit(s.text, 40, 20, 700), color: T.fg, valign: 'middle', align: 'center' });
          sl.addText([s.ref || '', s.version ? '  ·  ' + s.version : ''].join(''), { x: M, y: 5.6, w: W - 2 * M, h: 0.6, fontFace: sans, bold: true, fontSize: 22, color: T.accent, align: 'center' });
          break;

        case 'topicos': {
          if (s.title) sl.addText(s.title, { x: M, y: 0.5, w: W - 2 * M, h: 1.0, fontFace: serif, bold: true, fontSize: fit(s.title, 40, 28, 80), color: T.fg });
          var items = (s.items || []).filter(function (x) { return x && x.trim(); });
          var total = items.join(' ').length;
          var fs = fit(items.join(' '), 28, 16, 700);
          var runs = items.map(function (t) {
            return { text: t, options: { bullet: { code: '25CF' }, color: T.fg, fontSize: fs, paraSpaceAfter: 10, breakLine: true } };
          });
          if (runs.length) sl.addText(runs, { x: M, y: s.title ? 1.6 : 0.8, w: s.img ? 7.2 : W - 2 * M, h: s.title ? 4.6 : 5.4, fontFace: sans, valign: 'top' });
          pic(s.img, 8.3, 1.6, 4.3, 4.3);
          void total;
          break;
        }

        case 'imagem':
          pic(s.img, M, 0.45, W - 2 * M, s.title ? 5.6 : 6.3);
          if (s.title) sl.addText(s.title, { x: M, y: 6.1, w: W - 2 * M, h: 0.5, fontFace: sans, fontSize: 20, color: T.fg, align: 'center' });
          break;

        case 'pagina':
          sl.background = { color: '000000' };
          pic(s.img, 0, 0, W, H);
          break;

        case 'discussao':
          label(s.text || 'Para conversar', 1.2);
          sl.addText(s.title || '', { x: M, y: 1.8, w: W - 2 * M, h: 3.8, fontFace: serif, bold: true, fontSize: fit(s.title, 46, 28, 220), color: T.fg, valign: 'middle' });
          break;

        case 'quiz': {
          sl.addText(s.title || '', { x: M, y: 0.5, w: W - 2 * M, h: 1.6, fontFace: serif, bold: true, fontSize: fit(s.title, 38, 24, 180), color: T.fg, valign: 'middle' });
          var opts = (s.items || []).filter(function (x) { return x && x.trim(); });
          var colW = (W - 2 * M - 0.3) / 2, rowH = 1.75;
          opts.slice(0, 4).forEach(function (o, j) {
            var x = M + (j % 2) * (colW + 0.3), y = 2.3 + Math.floor(j / 2) * (rowH + 0.25);
            var right = fr.step === 1 && j === (s.ok || 0);
            var dim = fr.step === 1 && !right;
            sl.addShape(p.ShapeType.roundRect, { x: x, y: y, w: colW, h: rowH, rectRadius: 0.12, fill: { color: right ? T.ok : T.card, transparency: dim ? 40 : 0 }, line: { color: right ? T.ok : T.accent, transparency: right ? 0 : 65, width: 1 } });
            sl.addText([
              { text: LETTERS[j] + '  ', options: { bold: true, color: right ? '10200C' : T.accent } },
              { text: o, options: { color: right ? '10200C' : T.fg } }
            ], { x: x + 0.25, y: y, w: colW - 0.5, h: rowH, fontFace: sans, fontSize: fit(o, 26, 16, 120), valign: 'middle' });
          });
          break;
        }
      }
    });
    return p.write({ outputType: 'base64' });
  }

  // ---------- ler PowerPoint ----------

  function xmlText(node, tag) {
    var out = [];
    var ps = node.getElementsByTagName('a:p');
    for (var i = 0; i < ps.length; i++) {
      var ts = ps[i].getElementsByTagName('a:t'), line = '';
      for (var j = 0; j < ts.length; j++) line += ts[j].textContent;
      line = line.trim();
      if (line) out.push(line);
    }
    void tag;
    return out;
  }

  /**
   * Lê um .pptx (ArrayBuffer ou base64) e devolve { slides: [{ title, items, img, notes }], media: { nome: dataURL } }.
   * Traz o texto de cada slide (o primeiro bloco vira título) e a maior imagem do slide.
   */
  function parsePptx(data, JSZipLib, DOMParserLib) {
    JSZipLib = JSZipLib || root.JSZip;
    var DP = DOMParserLib || root.DOMParser;
    return JSZipLib.loadAsync(data, typeof data === 'string' ? { base64: true } : {}).then(function (zip) {
      var pres = zip.file('ppt/presentation.xml');
      var relsF = zip.file('ppt/_rels/presentation.xml.rels');
      if (!pres || !relsF) throw new Error('Este arquivo não parece um PowerPoint (.pptx).');
      return Promise.all([pres.async('string'), relsF.async('string')]).then(function (r) {
        var pdoc = new DP().parseFromString(r[0], 'application/xml');
        var rdoc = new DP().parseFromString(r[1], 'application/xml');
        var rel = {};
        var rs = rdoc.getElementsByTagName('Relationship');
        for (var i = 0; i < rs.length; i++) rel[rs[i].getAttribute('Id')] = rs[i].getAttribute('Target');
        var ids = pdoc.getElementsByTagName('p:sldId');
        var paths = [];
        for (var k = 0; k < ids.length; k++) {
          var rid = ids[k].getAttribute('r:id');
          if (rel[rid]) paths.push('ppt/' + rel[rid].replace(/^\.?\//, '').replace(/^\/ppt\//, ''));
        }
        var media = {};
        var seq = 0;
        return paths.reduce(function (chain, path) {
          return chain.then(function (acc) {
            var f = zip.file(path);
            if (!f) return acc;
            var dir = path.substring(0, path.lastIndexOf('/'));
            var name = path.substring(path.lastIndexOf('/') + 1);
            var relPath = dir + '/_rels/' + name + '.rels';
            return Promise.all([f.async('string'), zip.file(relPath) ? zip.file(relPath).async('string') : Promise.resolve('')]).then(function (x) {
              var sdoc = new DP().parseFromString(x[0], 'application/xml');
              var srel = {};
              var notesPath = null;
              if (x[1]) {
                var rr = new DP().parseFromString(x[1], 'application/xml').getElementsByTagName('Relationship');
                for (var i = 0; i < rr.length; i++) {
                  srel[rr[i].getAttribute('Id')] = rr[i].getAttribute('Target');
                  if (/notesSlide/.test(rr[i].getAttribute('Type') || '')) notesPath = rr[i].getAttribute('Target');
                }
              }
              // blocos de texto na ordem do slide
              var sps = sdoc.getElementsByTagName('p:sp');
              var found = [];
              var title = '';
              for (var i = 0; i < sps.length; i++) {
                var ph = sps[i].getElementsByTagName('p:ph')[0];
                var lines = xmlText(sps[i]).filter(function (l) { return !/^\d+(\s*\/\s*\d+)?$/.test(l); });
                if (!lines.length) continue;
                var t = ph ? ph.getAttribute('type') : '';
                if (t === 'sldNum' || t === 'ftr' || t === 'dt') continue;
                if (!title && (t === 'title' || t === 'ctrTitle')) { title = lines.join(' '); continue; }
                var sz = 0, rp = sps[i].getElementsByTagName('a:rPr');
                for (var q = 0; q < rp.length; q++) sz = Math.max(sz, +rp[q].getAttribute('sz') || 0);
                found.push({ lines: lines, sz: sz });
              }
              if (!title && found.length) {
                var bi = 0;
                found.forEach(function (f, k) { if (f.sz > found[bi].sz) bi = k; });
                if (found[bi].lines.join(' ').length <= 140) title = found.splice(bi, 1)[0].lines.join(' ');
              }
              var blocks = [];
              found.forEach(function (f) { blocks = blocks.concat(f.lines); });
              // maior imagem do slide
              var pics = sdoc.getElementsByTagName('p:pic');
              var best = null, bestArea = 0;
              for (var j = 0; j < pics.length; j++) {
                var blip = pics[j].getElementsByTagName('a:blip')[0];
                var ext = pics[j].getElementsByTagName('a:ext')[0];
                if (!blip) continue;
                var target = srel[blip.getAttribute('r:embed')];
                if (!target) continue;
                var area = ext ? (+ext.getAttribute('cx') || 1) * (+ext.getAttribute('cy') || 1) : 1;
                if (area > bestArea) { bestArea = area; best = target; }
              }
              var job = Promise.resolve(null);
              if (best) {
                var ip = resolve(dir, best);
                var lower = ip.toLowerCase();
                var mime = /\.png$/.test(lower) ? 'image/png' : /\.jpe?g$/.test(lower) ? 'image/jpeg' : /\.gif$/.test(lower) ? 'image/gif' : null;
                if (mime && zip.file(ip)) {
                  job = zip.file(ip).async('base64').then(function (b) {
                    var nm = 'pptx-' + (++seq) + (mime === 'image/png' ? '.png' : mime === 'image/gif' ? '.gif' : '.jpg');
                    media[nm] = 'data:' + mime + ';base64,' + b;
                    return nm;
                  });
                }
              }
              var notesJob = Promise.resolve('');
              if (notesPath) {
                var np = resolve(dir, notesPath);
                if (zip.file(np)) notesJob = zip.file(np).async('string').then(function (nx) {
                  var nd = new DP().parseFromString(nx, 'application/xml');
                  var bodies = nd.getElementsByTagName('p:sp'), out = [];
                  for (var i = 0; i < bodies.length; i++) {
                    var ph = bodies[i].getElementsByTagName('p:ph')[0];
                    if (ph && ph.getAttribute('type') === 'body') out = out.concat(xmlText(bodies[i]));
                  }
                  return out.join('\n');
                });
              }
              return Promise.all([job, notesJob]).then(function (y) {
                acc.push({ title: title, items: blocks, img: y[0], notes: y[1] });
                return acc;
              });
            });
          });
        }, Promise.resolve([])).then(function (slides) { return { slides: slides, media: media }; });
      });
    });
  }

  function resolve(dir, target) {
    if (target.charAt(0) === '/') return target.substring(1);
    var parts = dir.split('/');
    target.split('/').forEach(function (seg) {
      if (seg === '..') parts.pop(); else if (seg !== '.') parts.push(seg);
    });
    return parts.join('/');
  }

  /** Converte o resultado de parsePptx em slides da aula (tópicos, imagem ou título). */
  function slidesFromPptx(parsed, newId) {
    return parsed.slides.map(function (s, i) {
      var base = { id: newId ? newId() : 'p' + i, notes: s.notes || '' };
      if (!s.items.length && s.img) return Object.assign(base, { kind: 'imagem', title: s.title || '', img: s.img });
      if (!s.items.length) return Object.assign(base, { kind: 'titulo', title: s.title || ' ', text: '' });
      return Object.assign(base, { kind: 'topicos', title: s.title || '', items: s.items.slice(0, 12), img: s.img || undefined });
    });
  }

  // ---------- arquivo da aula (.vvaula) ----------

  function pack(aula, media, JSZipLib) {
    JSZipLib = JSZipLib || root.JSZip;
    var z = new JSZipLib();
    z.file('aula.json', JSON.stringify(aula));
    Object.keys(media || {}).forEach(function (k) {
      var d = media[k];
      z.file('media/' + k, d.substring(d.indexOf(',') + 1), { base64: true });
    });
    return z.generateAsync({ type: 'base64', compression: 'STORE' });
  }

  function unpack(data, JSZipLib) {
    JSZipLib = JSZipLib || root.JSZip;
    return JSZipLib.loadAsync(data, typeof data === 'string' ? { base64: true } : {}).then(function (z) {
      var f = z.file('aula.json');
      if (!f) throw new Error('Este arquivo não é uma aula do Verso Vivo.');
      return f.async('string').then(function (txt) {
        var aula = JSON.parse(txt);
        var media = {};
        var jobs = [];
        z.folder('media').forEach(function (rel, file) {
          if (file.dir) return;
          var lower = rel.toLowerCase();
          var mime = /\.png$/.test(lower) ? 'image/png' : /\.gif$/.test(lower) ? 'image/gif' : 'image/jpeg';
          jobs.push(file.async('base64').then(function (b) { media[rel] = 'data:' + mime + ';base64,' + b; }));
        });
        return Promise.all(jobs).then(function () { return { aula: aula, media: media }; });
      });
    });
  }

  var api = { backdrop: backdrop, dims: dims, contain: contain, THEMES: THEMES, KINDS: KINDS, LETTERS: LETTERS, theme: theme, frames: frames, hasReveal: hasReveal, fit: fit,
    toPptx: toPptx, parsePptx: parsePptx, slidesFromPptx: slidesFromPptx, pack: pack, unpack: unpack };
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  root.AulaKit = api;
})(typeof window !== 'undefined' ? window : globalThis);
