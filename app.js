/* ===== utilidades ===== */
const app=document.getElementById('app');
const KEY='lumi-catecismo-v1';
let P={m:{},seen:{},last:null};
try{const r=localStorage.getItem(KEY);if(r)P=Object.assign(P,JSON.parse(r));}catch(e){}
function save(){try{localStorage.setItem(KEY,JSON.stringify(P))}catch(e){}}
const esc=s=>String(s).replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const range=(a,b)=>Array.from({length:b-a+1},(_,i)=>a+i);
const nums=u=>u<0?range(1,107):range(U[u].a,U[u].b);
const shuffle=a=>{a=a.slice();for(let i=a.length-1;i>0;i--){const j=Math.floor(Math.random()*(i+1));[a[i],a[j]]=[a[j],a[i]]}return a};
const pick=a=>a[Math.floor(Math.random()*a.length)];
const norm=w=>w.normalize('NFD').replace(/[̀-ͯ]/g,'').toLowerCase().replace(/[^a-z0-9-]/g,'');
const bare=w=>w.replace(/^[“”"(]+|[“”")\.,;:!?]+$/g,'');
const stars=n=>P.m[n]||0;
const unitOf=n=>U.findIndex(u=>n>=u.a&&n<=u.b);
const pct=list=>Math.round(list.reduce((s,n)=>s+stars(n),0)/(list.length*3)*100);
const STOP=new Set("que para como pela pelo pelas pelos nossa nosso nossos nossas todas todos toda todo mesmo sobre entre aquele aqueles aquela aquelas tambem quando porque dele dela delas deles desta deste destas destes mais isto isso seus suas sua seu cada esta este estas estes nesta neste muito sendo assim pois qual quais nele nela nelas neles numa outro outros outra outras ainda aos das dos".split(' '));

function flameSVG(on){return `<svg viewBox="0 0 12 16" aria-hidden="true"><path class="${on?'on':'off'}" d="M6 15C2.5 15 1 12.5 1.6 9.8 2.2 7.2 4.6 6 5 1c2.6 2.3 5.4 5.4 5.4 9 0 3-1.8 5-4.4 5z"/></svg>`}
function flamesRow(n){const s=stars(n);return `<span class="flames" aria-label="${s} de 3">${[0,1,2].map(i=>flameSVG(i<s)).join('')}</span>`}

function bushSVG(){
  const fl=(x,h,w,l,base)=>`M${x} ${base} C${x-w} ${base-h*.35} ${x-w*.55+l} ${base-h*.78} ${x+l} ${base-h} C${x+w*.55+l} ${base-h*.72} ${x+w} ${base-h*.35} ${x} ${base}Z`;
  const outer=[[20,30,10,-4],[34,46,11,-3],[48,58,12,-1],[61,66,12,0],[74,58,12,1],[88,46,11,3],[102,30,10,4]];
  const inner=[[34,24,5,-2],[48,32,6,-1],[61,38,6,0],[74,32,6,1],[88,24,5,2]];
  return `<svg class="bush" viewBox="0 0 122 92" aria-hidden="true">${outer.map(f=>`<path class="f1" d="${fl(f[0],f[1],f[2],f[3],78)}"/>`).join('')}${inner.map(f=>`<path class="f2" d="${fl(f[0],f[1],f[2],f[3],78)}"/>`).join('')}<rect class="bar" x="16" y="84" width="90" height="4" rx="2"/></svg>`;
}
/* ===== Lumi: humores e reações =====
   moods: idle, happy, cheer, sad, think, sleep */
function lumiSVG(mood='idle'){
  const W='stroke="#fff" fill="none" stroke-linecap="round"';
  const eyes={
    idle:`<g class="eyes"><circle cx="66" cy="32" r="2" fill="#fff"/><circle cx="74" cy="32" r="2" fill="#fff"/></g>`,
    happy:`<g class="eyes"><circle cx="66" cy="32" r="2.1" fill="#fff"/><circle cx="74" cy="32" r="2.1" fill="#fff"/></g>`,
    cheer:`<path d="M63.8 33q2.2-2.8 4.4 0M71.8 33q2.2-2.8 4.4 0" ${W} stroke-width="1.7"/>`,
    sad:`<path d="M63.4 30.4l4-1.8M76.6 30.4l-4-1.8" ${W} stroke-width="1.4"/><circle cx="66" cy="33" r="1.6" fill="#fff"/><circle cx="74" cy="33" r="1.6" fill="#fff"/>`,
    think:`<circle cx="66" cy="32" r="2.6" fill="#fff"/><circle cx="74" cy="32" r="2.6" fill="#fff"/><circle cx="67" cy="30.9" r="1.15" fill="var(--face)"/><circle cx="75" cy="30.9" r="1.15" fill="var(--face)"/>`,
    sleep:`<path d="M63.8 32q2.2 2.2 4.4 0M71.8 32q2.2 2.2 4.4 0" ${W} stroke-width="1.6"/>`,
    meh:`<path d="M71.8 28.4l4.4-.9" ${W} stroke-width="1.4"/><circle cx="65.4" cy="32.4" r="1.9" fill="#fff"/><circle cx="73.4" cy="32.4" r="1.9" fill="#fff"/>`
  }[mood]||'';
  const mouth={
    idle:`<path d="M66 39q3.5 3.2 7 0" ${W} stroke-width="1.7"/>`,
    happy:`<path d="M65 38.6q4.5 4.6 9 0" ${W} stroke-width="1.8"/>`,
    cheer:`<path d="M65.4 38.4q4.1 6.4 8.2 0z" fill="#fff"/>`,
    sad:`<path d="M66 41.8q3.5-2.8 7 0" ${W} stroke-width="1.7"/>`,
    think:`<path d="M67.6 40.4h4" ${W} stroke-width="1.7"/>`,
    sleep:`<circle cx="69.6" cy="40" r="1.3" ${W} stroke-width="1.3"/>`,
    meh:`<path d="M65.8 40.4q1.8-1.4 3.6 0t3.6 0" ${W} stroke-width="1.6"/>`
  }[mood]||'';
  const cheeks=(mood==='happy'||mood==='cheer')?`<ellipse cx="62.8" cy="37.2" rx="2" ry="1.3" fill="#f2a0a6" opacity=".75"/><ellipse cx="77.2" cy="37.2" rx="2" ry="1.3" fill="#f2a0a6" opacity=".75"/>`:'';
  const extra={
    sad:`<path class="tear" d="M63 37.5c-1.2 2-1.6 3-1.6 3.8a1.6 1.6 0 0 0 3.2 0c0-.8-.4-1.8-1.6-3.8z" fill="#7cc4f0"/>`,
    think:`<g class="dots" fill="var(--gold)"><circle cx="86" cy="15" r="1.6"/><circle cx="91" cy="9" r="2.1"/><circle cx="97" cy="2" r="2.7"/></g>`,
    sleep:`<g class="zz" fill="currentColor" font-family="var(--f-display)" font-weight="700"><text x="82" y="16" font-size="8">z</text><text x="89" y="7" font-size="11">z</text></g>`,
    cheer:`<g class="spark" fill="var(--gold)"><path d="M8 10l1.6 3.4L13 15l-3.4 1.6L8 20l-1.6-3.4L3 15l3.4-1.6z"/><path d="M90 2l1.2 2.6L94 6l-2.8 1.4L90 10l-1.2-2.6L86 6l2.8-1.4z"/><path d="M4 40l1 2 2 1-2 1-1 2-1-2-2-1 2-1z"/></g>`
  }[mood]||'';
  return `<svg class="lumi" data-mood="${mood}" viewBox="-2 -6 102 82" aria-hidden="true" style="color:var(--fg)">
  <g class="body"><path d="M30 55v12M42 57v12M56 57v12" stroke="currentColor" stroke-width="3.4" stroke-linecap="round"/>
  <path fill="var(--wool)" stroke="currentColor" stroke-width="2.2" d="M20 42c-8 0-11-8-7-13 0-8 9-11 14-8 3-7 13-8 17-3 6-4 15-1 16 5 7 0 11 7 8 12 4 6 0 13-7 13-1 6-9 9-14 5-4 5-13 5-16 0-7 3-13-1-11-11z"/></g>
  <g class="head"><ellipse class="ear" cx="61" cy="25" rx="7" ry="3.4" transform="rotate(-28 61 25)" fill="var(--face)"/>
  <ellipse cx="70" cy="34" rx="10.5" ry="12.5" fill="var(--face)"/>
  <ellipse cx="80" cy="27" rx="6" ry="3" transform="rotate(25 80 27)" fill="var(--face)"/>
  ${eyes}${cheeks}${mouth}${extra}
  <path class="flame" d="M60 14c2-4 1-7 0-9 3 2 6 5 5 9-1 2-3 2-5 0z" fill="var(--gold)"/></g>
  </svg>`;
}
function lumiReact(mood,ms=850){
  const el=document.querySelector('.lumi-live');if(!el)return;
  el.innerHTML=lumiSVG(mood);el.firstElementChild.classList.add(mood==='sad'?'shake':mood==='meh'?'tilt':'hop');
  clearTimeout(lumiReact.t);
  lumiReact.t=setTimeout(()=>{const e=document.querySelector('.lumi-live');if(e&&S.v==='game'&&!S.g.done)e.innerHTML=lumiSVG('think')},ms);
}
/* datas e semana */
const today=()=>{const d=new Date();return d.getFullYear()+'-'+String(d.getMonth()+1).padStart(2,'0')+'-'+String(d.getDate()).padStart(2,'0')};
function markDay(){P.days=P.days||{};P.days[today()]=1;P.lastDay=today();}
function daysSince(day){if(!day)return Infinity;const [y,m,d]=day.split('-').map(Number);return Math.round((new Date(new Date().toDateString())-new Date(y,m-1,d))/864e5)}
function weekQ(){
  // a pergunta muda todo domingo: semana 1 começou em 4/jan/2026, e o ciclo recomeça depois da 107
  const base=new Date(2026,0,4),now=new Date(new Date().toDateString());
  const w=Math.floor((now-base)/(7*864e5));const n=((w%107)+107)%107+1;
  const start=new Date(base.getTime()+w*7*864e5),end=new Date(start.getTime()+6*864e5);
  const f=d=>d.toLocaleDateString('pt-BR',{day:'numeric',month:'short'}).replace('.','');
  return {n,label:`${f(start)} a ${f(end)}`};
}
function greet(){const h=new Date().getHours();return h<12?'Bom dia':h<18?'Boa tarde':'Boa noite'}
function lumiLine(){
  if(S.poke){const n=S.poke.n;const q=Q[n-1];
    if(!S.poke.rev)return {mood:'think',html:`Você lembra a pergunta ${n}?<br><b>${esc(q[0])}</b><br><button class="linkbtn" data-act="pokerev">Mostrar resposta</button>`};
    return {mood:'cheer',html:`<b>${n}.</b> ${esc(trunc(q[1],190))}<br><button class="linkbtn" data-act="poke">Outra pergunta</button>`};}
  const all=range(1,107),learned=all.filter(n=>stars(n)>0).length,mastered=all.filter(n=>stars(n)>=3).length;
  const wk=weekQ();const last=P.last!=null&&U[P.last]?P.last:0;const ds=daysSince(P.lastDay);
  if(!learned)return {mood:'happy',html:`${greet()}! Eu sou a Lumi. Vamos aprender o Catecismo juntos? Toque em mim para uma pergunta surpresa.`};
  if(ds>=4)return {mood:'sleep',html:`Zzz… ah, ${greet().toLowerCase()}! Faz ${ds} dias que não estudamos. Que tal revisar a lição ${last+1}?`};
  if(ds===0)return {mood:'happy',html:`Você já estudou hoje! ${mastered?`Já são ${mastered} pergunta${mastered>1?'s':''} dominada${mastered>1?'s':''}.`:'Continue que as chamas vão acender.'}`};
  return {mood:'idle',html:`${greet()}! A pergunta da semana é a ${wk.n}. Vamos estudar?`};
}

function speak(text){
  try{const s=window.speechSynthesis;s.cancel();const u=new SpeechSynthesisUtterance(text.replace(/[“”]/g,''));u.lang='pt-BR';u.rate=.95;
  const v=s.getVoices().find(v=>/^pt/i.test(v.lang));if(v)u.voice=v;s.speak(u);}catch(e){}
}

/* ===== estado e navegação ===== */
const S={v:'home'};
function go(v,extra){document.querySelectorAll('.confetti').forEach(c=>c.remove());Object.assign(S,{v},extra||{});try{speechSynthesis.cancel()}catch(e){};render();window.scrollTo(0,0)}

function topbar(title,back,right){
  return `<div class="topbar"><div class="wrap"><button class="back" data-act="${back}" aria-label="Voltar">‹ Voltar</button><span class="tt">${esc(title)}</span>${right?`<span class="count">${right}</span>`:''}</div></div>`;
}

/* ===== telas ===== */
function vHome(){
  const all=range(1,107), p=pct(all);
  const learned=all.filter(n=>stars(n)>0).length;
  const days=Object.keys(P.days||{}).length;
  const last=P.last!=null&&U[P.last]?P.last:null;
  const wk=weekQ(), line=lumiLine();
  return `
  <div class="band"><div class="wrap hero">
    <div class="hero-text"><p class="eyebrow">Lumi · Catecismo</p>
    <h1 class="roll" aria-label="Breve Catecismo de Westminster">${rollHTML('Breve Catecismo de Westminster')}</h1>
    <p>107 perguntas e respostas para aprender juntos, em casa e na igreja.</p></div>
    <div class="lumi-row">
      <div class="bubble" aria-live="polite">${line.html}</div>
      <button class="lumi-stage" data-act="poke" aria-label="Pedir uma pergunta surpresa à Lumi">${bushSVG()}${lumiSVG(line.mood)}</button>
    </div>
    <div class="hero-stats"><span><b>${p}%</b> do Catecismo</span><span><b>${learned}</b> de 107 praticadas</span><span><b>${days}</b> dia${days===1?'':'s'} de estudo</span></div>
    <div class="overall" title="${p}% concluído"><i style="width:${p}%"></i></div>
  </div></div>
  <main class="wrap">
    <section class="week">
      <div class="week-head"><span class="eyebrow">Pergunta da semana · ${wk.label}</span><span class="week-n">${wk.n}</span></div>
      <p class="week-q">${esc(Q[wk.n-1][0])}</p>
      <div class="row"><button class="btn solid" data-act="weekstudy">Estudar</button><button class="btn" data-act="weekclass">Projetar na classe</button></div>
    </section>
    ${last!=null?`<button class="continue" data-act="unit" data-u="${last}"><span class="cont-n">${last+1}</span><span><span class="eyebrow">Continuar</span><b>${esc(U[last].t)}</b><span class="ls">Perguntas ${U[last].a}–${U[last].b} · ${pct(nums(last))}% dominado</span></span><span class="chev">›</span></button>`:''}
    <section>
      <div class="sec-h"><h2>Lições</h2><span class="ls">3 chamas = pergunta dominada</span></div>
      <ul class="lessons">${U.map((u,i)=>{const pp=pct(nums(i));return `<li><button class="lesson" data-act="unit" data-u="${i}">
        <span class="num">${i+1}</span>
        <span style="min-width:0"><span class="lt">${esc(u.t)}</span><span class="ls">Perguntas ${u.a}–${u.b}</span><span class="mini"><i style="width:${pp}%"></i></span></span>
        <span class="chev">›</span></button></li>`}).join('')}</ul>
    </section>
    <section>
      <div class="sec-h"><h2>Na igreja</h2></div>
      <div class="tools">
        <button class="tool primary" data-act="class"><b>Modo Classe</b><span>Projetar perguntas, revelar respostas e marcar pontos por equipe.</span></button>
        <button class="tool" data-act="review"><b>Revisão geral</b><span>8 perguntas sorteadas de todo o Catecismo.</span></button>
      </div>
    </section>
    <section>
      <div class="sec-h"><h2>Textos para decorar</h2></div>
      <div class="tools">
        <button class="tool" data-act="text" data-t="mand"><b>Dez Mandamentos</b><span>Êx 20.3-17</span></button>
        <button class="tool" data-act="text" data-t="pai"><b>Pai Nosso</b><span>Mt 6.9-13</span></button>
        <button class="tool" data-act="text" data-t="credo"><b>Credo</b><span>Credo Apostólico</span></button>
      </div>
    </section>
    <p class="foot">O progresso fica salvo neste aparelho.</p>
  </main>`;
}

function vUnit(){
  const u=U[S.u], list=nums(S.u);
  return topbar(`Lição ${S.u+1}`,'home',pct(list)+'%')+`
  <main class="wrap">
    <div><p class="eyebrow">Lição ${S.u+1} · Perguntas ${u.a}–${u.b}</p><h1 style="font-size:1.8rem;margin-top:4px">${esc(u.t)}</h1></div>
    <div class="tools">
      <button class="tool primary" data-act="study" data-i="0"><b>Estudar</b><span>Ler, ouvir e revelar cada resposta.</span></button>
      <button class="tool" data-act="play" data-mode="quiz"><b>Quiz</b><span>Escolha a resposta certa.</span></button>
      <button class="tool" data-act="play" data-mode="complete"><b>Completar</b><span>Encaixe as palavras que faltam.</span></button>
      <button class="tool" data-act="play" data-mode="build"><b>Montar</b><span>Coloque os trechos na ordem.</span></button>
      <button class="tool" data-act="play" data-mode="mix"><b>Desafio</b><span>Tudo misturado, para fixar.</span></button>
    </div>
    <section>
      <div class="sec-h"><h2>Perguntas</h2><span class="ls">3 chamas = dominada</span></div>
      <ul class="qlist">${list.map((n,i)=>`<li><button class="qrow" data-act="study" data-i="${i}"><span class="n">${n}</span><span>${esc(Q[n-1][0])}</span>${flamesRow(n)}</button></li>`).join('')}</ul>
    </section>
  </main>`;
}

function vStudy(){
  const list=nums(S.u), n=list[S.i], [q,a,r]=Q[n-1];
  return topbar(U[S.u].t,'backunit',`${S.i+1}/${list.length}`)+`
  <main class="wrap">
    <article class="card">
      <div class="qnum">Pergunta ${n}</div>
      <div class="qtext">${esc(q)}</div>
      <div class="atext ${S.rev?'':'hidden'}" ${S.rev?'':'aria-hidden="true"'}>${esc(a)}</div>
      <div class="row">
        ${S.rev?'':`<button class="btn solid" data-act="reveal">Mostrar resposta</button>`}
        <button class="btn" data-act="speak">▶ Ouvir</button>
      </div>
      <div class="refs"><b>Referências:</b> ${esc(r)}</div>
    </article>
    <div class="nav">
      <button class="btn" data-act="sprev" ${S.i===0?'disabled':''}>‹ Anterior</button>
      ${S.i<list.length-1?`<button class="btn solid" data-act="snext">Próxima ›</button>`:`<button class="btn gold" data-act="play" data-mode="mix">Fazer o desafio</button>`}
    </div>
  </main>`;
}

/* --- jogos --- */
function chunksOf(a){
  let parts=a.split(/(?<=[,;:])\s+/).filter(Boolean);
  let out=[];
  parts.forEach(p=>{const w=p.split(/\s+/);
    if(w.length>8){const k=Math.ceil(w.length/6);const sz=Math.ceil(w.length/k);for(let i=0;i<w.length;i+=sz)out.push(w.slice(i,i+sz).join(' '));}
    else out.push(p);});
  // junta pedaços muito curtos
  out=out.reduce((acc,c)=>{if(acc.length&&c.split(' ').length<2)acc[acc.length-1]+=' '+c;else acc.push(c);return acc},[]);
  while(out.length>7){let best=0,bl=1e9;for(let i=0;i<out.length-1;i++){const l=out[i].length+out[i+1].length;if(l<bl){bl=l;best=i}}out.splice(best,2,out[best]+' '+out[best+1]);}
  if(out.length<3){const w=a.split(/\s+/);const sz=Math.ceil(w.length/3);out=[];for(let i=0;i<w.length;i+=sz)out.push(w.slice(i,i+sz).join(' '));}
  return out;
}
function candidates(n){
  const [q,a]=Q[n-1];const qs=new Set(q.split(/\s+/).map(norm));
  const words=a.split(/\s+/);
  return {words,c:words.map((w,i)=>({i,k:norm(w)})).filter(o=>o.k.length>=4&&!STOP.has(o.k)&&!qs.has(o.k))};
}
function setupItem(){
  const g=S.g,it=g.items[g.i],n=it.n,[q,a]=Q[n-1];
  g.done=false;g.miss=0;g.correct=null;
  if(it.mode==='complete'){
    const {words,c}=candidates(n);
    const k=Math.min(c.length, words.length<15?2:words.length<35?3:4);
    if(k<1){it.mode='quiz';return setupItem();}
    const seenK=new Set();const chosen=[];
    for(const o of shuffle(c)){if(chosen.length>=k)break;if(!seenK.has(o.k)){seenK.add(o.k);chosen.push(o)}}
    chosen.sort((x,y)=>x.i-y.i);
    const others=shuffle(range(1,107).filter(m=>m!==n)).slice(0,6).flatMap(m=>candidates(m).c.map(o=>bare(candidates(m).words[o.i])));
    const distract=[];for(const w of shuffle(others)){if(distract.length>=2)break;if(!seenK.has(norm(w))&&!distract.some(d=>norm(d)===norm(w)))distract.push(w)}
    g.st={words,blanks:chosen.map(o=>o.i),filled:0,bank:shuffle([...chosen.map(o=>bare(words[o.i])),...distract]).map(w=>({w,used:false}))};
  } else if(it.mode==='build'){
    const ch=chunksOf(a);
    g.st={chunks:ch,order:shuffle(ch.map((_,i)=>i)),placed:[],used:new Set()};
    if(g.st.order.every((v,i)=>v===i)&&ch.length>1)g.st.order.reverse();
  } else {
    const list=g.pool.filter(m=>m!==n);
    const wrong=shuffle(list.length>=3?list:range(1,107).filter(m=>m!==n)).slice(0,3);
    g.st={opts:shuffle([n,...wrong]),chosen:null};
  }
}
function startGame(mode,pool,back){
  const sel=shuffle(pool).slice(0,Math.min(8,pool.length));
  const modes=['quiz','complete','build'];
  S.g={pool,back,mode,i:0,ok:0,items:sel.map(n=>({n,mode:mode==='mix'?pick(modes):mode}))};
  setupItem();go('game');
}
const MODE_NAME={quiz:'Quiz',complete:'Completar',build:'Montar',mix:'Desafio'};
const PRAISE=['Muito bem!','Isso mesmo!','Correto!','Boa memória!','Excelente!'];
function trunc(s,m){return s.length>m?s.slice(0,m).replace(/\s+\S*$/,'')+'…':s}

function vGame(){
  const g=S.g,it=g.items[g.i],n=it.n,[q,a,r]=Q[n-1];
  const dots=g.items.map((_,i)=>`<i class="${i<g.i?'d':i===g.i?'c':''}"></i>`).join('');
  let body='';
  if(it.mode==='quiz'){
    body=`<p class="prompt-label">Qual é a resposta?</p><div class="opts">${g.st.opts.map(m=>{
      let cls='';if(g.done){if(m===n)cls='right';else if(m===g.st.chosen)cls='wrong'}
      return `<button class="opt ${cls}" data-act="qopt" data-m="${m}" ${g.done?'disabled':''}>${esc(trunc(Q[m-1][1],170))}</button>`}).join('')}</div>`;
  } else if(it.mode==='complete'){
    const st=g.st;let bi=0;
    const txt=st.words.map((w,i)=>{const b=st.blanks.indexOf(i);if(b<0)return esc(w);
      const lead=(w.match(/^[“”"(]+/)||[''])[0],trail=(w.match(/[“”")\.,;:!?]+$/)||[''])[0];
      const filled=b<st.filled;const cur=b===st.filled&&!g.done;
      return `${esc(lead)}<span class="blank ${filled?'ok':''} ${cur?'cur':''}">${filled?esc(bare(w)):'·····'}</span>${esc(trail)}`}).join(' ');
    body=`<p class="prompt-label">Complete a resposta tocando nas palavras na ordem</p><div class="card"><div class="fill">${txt}</div></div>
      ${g.done?'':`<div class="bank">${st.bank.map((b,k)=>`<button class="chip ${b.used?'used':''}" data-act="cpick" data-k="${k}" ${b.used?'disabled':''}>${esc(b.w)}</button>`).join('')}</div>`}
      ${g.miss?`<p class="miss">${g.miss} tentativa${g.miss>1?'s':''} errada${g.miss>1?'s':''}</p>`:''}`;
  } else {
    const st=g.st;
    body=`<p class="prompt-label">Monte a resposta tocando nos trechos na ordem</p>
      <div class="built">${st.placed.map(i=>`<span>${esc(st.chunks[i])} </span>`).join('')}</div>
      ${g.done?'':`<div class="bank" style="flex-direction:column;align-items:stretch">${st.order.filter(i=>!st.used.has(i)).map(i=>`<button class="chip long" data-act="bpick" data-k="${i}">${esc(st.chunks[i])}</button>`).join('')}</div>`}
      ${g.miss?`<p class="miss">${g.miss} tentativa${g.miss>1?'s':''} errada${g.miss>1?'s':''}</p>`:''}`;
  }
  const fb=g.done?`<div class="feedback ${g.mood==='sad'?'bad':g.mood==='meh'?'meh':''}"><div class="wrap"><div class="fb">
    <h3>${g.mood==='cheer'?pick(PRAISE):g.mood==='meh'?(g.correct?'Quase perfeito!':'Quase!'):'Vamos revisar'}</h3>
    ${g.mood==='cheer'&&it.mode!=='quiz'?'':`<p><b>${n}.</b> ${esc(a)}</p>`}
    <p class="ls">${esc(r)}</p>
    <div class="row"><button class="btn solid" data-act="cont">${g.i<g.items.length-1?'Continuar':'Ver resultado'}</button><button class="btn" data-act="speakA">▶ Ouvir</button></div>
  </div></div></div>`:'';
  return topbar(MODE_NAME[g.mode],'quit',`${g.i+1}/${g.items.length}`)+`
  <main class="wrap" style="padding-bottom:${g.done?'12px':'48px'}">
    <div class="dots">${dots}</div>
    <div class="qhead"><div style="min-width:0"><div class="qnum">Pergunta ${n} · ${MODE_NAME[it.mode]}</div><div class="qtext" style="margin-top:6px">${esc(q)}</div></div><div class="lumi-live">${lumiSVG(g.done?g.mood:'think')}</div></div>
    ${body}
  </main>${fb}`;
}
function answered(ok){
  const g=S.g,n=g.items[g.i].n;g.done=true;g.correct=ok;g.mood=!g.miss?'cheer':g.miss===1?'meh':'sad';
  if(ok){g.ok++;P.m[n]=Math.min(3,(P.m[n]||0)+1)}
  P.seen[n]=1;markDay();save();render();
  const f=document.querySelector('.feedback');if(f)f.scrollIntoView({block:'end',behavior:'smooth'});
}

function vResult(){
  const g=S.g,t=g.items.length,r=g.ok/t;
  const msg=r===1?'Perfeito! Você sabe estas respostas.':r>=.6?'Muito bom. Mais uma rodada e fica firme.':'Vale estudar as respostas e tentar de novo.';
  const mood=r>=.8?'cheer':r>=.5?'happy':'sad';
  return topbar('Resultado',g.back==='home'?'home':'backunit','')+`
  <main class="wrap"><section class="card result">
    <div class="result-lumi">${lumiSVG(mood)}</div>
    <div class="big">${g.ok}/${t}</div>
    <h2>${msg}</h2>
    <ul class="qlist" style="width:100%;text-align:left">${g.items.map(it=>`<li><div class="qrow" style="cursor:default"><span class="n">${it.n}</span><span>${esc(Q[it.n-1][0])}</span>${flamesRow(it.n)}</div></li>`).join('')}</ul>
    <div class="row" style="justify-content:center"><button class="btn solid" data-act="again">Jogar de novo</button>${g.back==='home'?`<button class="btn" data-act="home">Início</button>`:`<button class="btn" data-act="study" data-i="0">Estudar a lição</button>`}</div>
  </section></main>`;
}
function confetti(){
  if(window.matchMedia&&matchMedia('(prefers-reduced-motion: reduce)').matches)return;
  const box=document.createElement('div');box.className='confetti';box.setAttribute('aria-hidden','true');
  for(let i=0;i<26;i++){const f=document.createElement('i');f.innerHTML=flameSVG(true);
    f.style.left=Math.random()*100+'%';f.style.animationDelay=(Math.random()*.6)+'s';f.style.animationDuration=(1.6+Math.random()*1.2)+'s';
    f.style.setProperty('--x',(Math.random()*80-40)+'px');f.style.setProperty('--r',(Math.random()*360)+'deg');box.appendChild(f)}
  document.body.appendChild(box);setTimeout(()=>box.remove(),3400);
}

/* --- Modo Classe --- */
function vClass(){
  const list=nums(S.cu), n=list[S.ci], [q,a,r]=Q[n-1];
  const sc=P.score||{a:0,b:0,on:false};
  return topbar('Modo Classe','home',`${S.ci+1}/${list.length}`)+`
  <div class="class">
    <div class="stage">
      <div class="class-top"><div class="qnum">Pergunta ${n}${S.cu>=0?' · Lição '+(S.cu+1):''}</div><div class="class-lumi">${lumiSVG(S.crev?'happy':'think')}</div></div>
      <div class="qtext">${esc(q)}</div>
      <div class="atext ${S.crev?'':'hidden'}">${esc(a)}</div>
      ${S.crev?`<div class="refs">${esc(r)}</div>`:''}
    </div>
    ${sc.on?`<div class="score"><div class="wrap">
      <div class="team"><span>Equipe 1</span><button class="btn sm" data-act="sc" data-t="a" data-v="-1" aria-label="Tirar ponto da equipe 1">−</button><b>${sc.a}</b><button class="btn sm solid" data-act="sc" data-t="a" data-v="1" aria-label="Ponto para a equipe 1">+</button></div>
      <div class="team"><span>Equipe 2</span><button class="btn sm" data-act="sc" data-t="b" data-v="-1" aria-label="Tirar ponto da equipe 2">−</button><b>${sc.b}</b><button class="btn sm solid" data-act="sc" data-t="b" data-v="1" aria-label="Ponto para a equipe 2">+</button></div>
      <button class="btn sm" data-act="sczero">Zerar</button>
    </div></div>`:''}
    <div class="controls"><div class="wrap">
      <select id="cu" aria-label="Lição"><option value="-1" ${S.cu<0?'selected':''}>Todas as perguntas</option>${U.map((u,i)=>`<option value="${i}" ${S.cu===i?'selected':''}>Lição ${i+1} · ${esc(u.t)}</option>`).join('')}</select>
      <button class="btn" data-act="cprev" ${S.ci===0?'disabled':''} aria-label="Pergunta anterior">‹</button>
      <button class="btn solid" data-act="crev">${S.crev?'Esconder':'Revelar'}</button>
      <button class="btn" data-act="cnext" ${S.ci>=list.length-1?'disabled':''} aria-label="Próxima pergunta">›</button>
      <button class="btn" data-act="crand">Sortear</button>
      <button class="btn" data-act="cspeak">▶ Ouvir</button>
      <button class="btn" data-act="sctoggle">${sc.on?'Esconder placar':'Placar'}</button>
      <button class="btn" data-act="full">Tela cheia</button>
    </div><p class="hint">Teclado: espaço revela · setas mudam · S sorteia</p></div>
  </div>`;
}

function vText(){
  const t=TEXTS[S.t];
  const body=t.list?`<ol>${t.list.map(x=>`<li>${esc(x)}</li>`).join('')}</ol><p>${esc(t.after)}</p>`:`<p>${esc(t.body)}</p>`;
  return topbar(t.t,'home','')+`<main class="wrap"><article class="card">
    <div><p class="eyebrow">${esc(t.ref)}</p><h1 style="font-size:1.7rem;margin-top:4px">${esc(t.t)}</h1></div>
    <div class="text-body">${body}</div>
    <div class="row"><button class="btn" data-act="speakT">▶ Ouvir</button></div></article></main>`;
}

function renderLumiRow(anim){
  const row=document.querySelector('.lumi-row');if(!row)return render();
  const line=lumiLine();row.querySelector('.bubble').innerHTML=line.html;
  const st=row.querySelector('.lumi-stage');st.querySelector('.lumi').outerHTML=lumiSVG(line.mood);
  if(anim)st.querySelector('.lumi').classList.add(anim);
}
function render(){
  app.innerHTML=({home:vHome,unit:vUnit,study:vStudy,game:vGame,result:vResult,class:vClass,text:vText}[S.v]||vHome)();
  if(S.v==='home')initRoll();
  if(S.v==='result'&&S.g&&S.g.ok===S.g.items.length&&!S.g.party){S.g.party=1;confetti()}
}

/* ===== Texto rolante da capa: letras rolam com atraso que nasce no centro ===== */
const ROLL={speed:.045,duration:.9};
function rollHTML(text){
  const n=text.replace(/ /g,'').length, mid=(n-1)/2; let i=0;
  return text.split(' ').map(word=>`<span class="rw" aria-hidden="true">${[...word].map(c=>{
    const d=Math.abs(i++-mid);
    return `<span class="rc" style="--d:${d.toFixed(1)}"><span class="ri"><span>${esc(c)}</span><span>${esc(c)}</span></span></span>`;
  }).join('')}</span>`).join('');
}
let rollRAF=0;
function initRoll(){
  const h=document.querySelector('h1.roll');if(!h)return;
  const reduce=window.matchMedia&&matchMedia('(prefers-reduced-motion: reduce)').matches;
  const cs=[...h.querySelectorAll('.rc')];const maxD=Math.max(...cs.map(c=>+c.style.getPropertyValue('--d')))||1;
  if(reduce){cs.forEach(c=>c.firstChild.style.transform='translateY(-50%)');return}
  // entrada: cada letra rola uma volta, do centro para as pontas
  cs.forEach(c=>{const d=+c.style.getPropertyValue('--d');c.firstChild.animate([{transform:'translateY(0)'},{transform:'translateY(-50%)'}],{duration:ROLL.duration*1000,delay:120+d*ROLL.speed*1000,easing:'cubic-bezier(.65,0,.25,1)',fill:'forwards'}).onfinish=function(){try{this.commitStyles()}catch(e){}this.cancel()}});
  // rolagem: ao descer a página as letras voltam a rolar, de novo a partir do centro
  const band=document.querySelector('.band');
  const onScroll=()=>{cancelAnimationFrame(rollRAF);rollRAF=requestAnimationFrame(()=>{
    if(!document.body.contains(h))return window.removeEventListener('scroll',onScroll);
    const p=Math.min(1,Math.max(0,window.scrollY/(band.offsetHeight*.9)));
    cs.forEach(c=>{const d=+c.style.getPropertyValue('--d')/maxD;const t=Math.min(1,Math.max(0,(p*1.6-d*.6)));
      const a=c.firstChild.getAnimations()[0];if(a&&a.playState!=='finished')return;
      c.firstChild.style.transform=`translateY(${-50+t*50}%)`;});
  })};
  window.addEventListener('scroll',onScroll,{passive:true});
}

/* ===== ações ===== */
const ACT={
  home:()=>{S.poke=null;go('home')},
  unit:b=>{const u=+b.dataset.u;P.last=u;save();go('unit',{u})},
  backunit:()=>go('unit'),
  study:b=>go('study',{i:+(b.dataset.i||0),rev:false}),
  reveal:()=>{S.rev=true;P.seen[nums(S.u)[S.i]]=1;markDay();save();render()},
  sprev:()=>go('study',{i:Math.max(0,S.i-1),rev:false}),
  snext:()=>go('study',{i:S.i+1,rev:false}),
  speak:()=>{const[q,a]=Q[nums(S.u)[S.i]-1];speak(S.rev?q+'. '+a:q)},
  play:b=>startGame(b.dataset.mode,nums(S.u),'unit'),
  review:()=>startGame('mix',range(1,107),'home'),
  quit:()=>go(S.g.back==='home'?'home':'unit'),
  again:()=>startGame(S.g.mode,S.g.pool,S.g.back),
  qopt:b=>{const m=+b.dataset.m,n=S.g.items[S.g.i].n;S.g.st.chosen=m;if(m!==n)S.g.miss=1;answered(m===n)},
  cpick:b=>{const g=S.g,st=g.st,k=+b.dataset.k,item=st.bank[k];
    const exp=norm(st.words[st.blanks[st.filled]]);
    if(norm(item.w)===exp){item.used=true;st.filled++;if(st.filled>=st.blanks.length)return answered(g.miss<=1);render();lumiReact('happy',700);}
    else{g.miss++;b.classList.remove('shake');void b.offsetWidth;b.classList.add('shake');const m=document.querySelector('.miss');if(m)m.textContent=`${g.miss} tentativa${g.miss>1?'s':''} errada${g.miss>1?'s':''}`;else render();lumiReact(g.miss>=2?'sad':'meh',900);}},
  bpick:b=>{const g=S.g,st=g.st,k=+b.dataset.k;const exp=st.chunks[st.placed.length];
    if(st.chunks[k]===exp){st.placed.push(k);st.used.add(k);if(st.placed.length===st.chunks.length)return answered(g.miss<=1);render();lumiReact('happy',700);}
    else{g.miss++;b.classList.remove('shake');void b.offsetWidth;b.classList.add('shake');const m=document.querySelector('.miss');if(m)m.textContent=`${g.miss} tentativa${g.miss>1?'s':''} errada${g.miss>1?'s':''}`;else render();lumiReact(g.miss>=2?'sad':'meh',900);}},
  cont:()=>{const g=S.g;g.i++;if(g.i>=g.items.length)return go('result');setupItem();go('game')},
  speakA:()=>{const n=S.g.items[S.g.i].n;speak(Q[n-1][0]+'. '+Q[n-1][1])},
  class:()=>go('class',{cu:P.last!=null?P.last:0,ci:0,crev:false}),
  crev:()=>{S.crev=!S.crev;render()},
  cprev:()=>{if(S.ci>0){S.ci--;S.crev=false;render()}},
  cnext:()=>{if(S.ci<nums(S.cu).length-1){S.ci++;S.crev=false;render()}},
  crand:()=>{const l=nums(S.cu);let i=S.ci;if(l.length>1)while(i===S.ci)i=Math.floor(Math.random()*l.length);S.ci=i;S.crev=false;render()},
  cspeak:()=>{const[q,a]=Q[nums(S.cu)[S.ci]-1];speak(S.crev?q+'. '+a:q)},
  full:()=>{try{if(document.fullscreenElement)document.exitFullscreen();else document.documentElement.requestFullscreen().catch(()=>{})}catch(e){}},
  text:b=>go('text',{t:b.dataset.t}),
  poke:()=>{const pool=range(1,107);let n;do{n=pick(pool)}while(S.poke&&n===S.poke.n);S.poke={n,rev:false};renderLumiRow('hop')},
  pokerev:()=>{if(S.poke){S.poke.rev=true;renderLumiRow('hop')}},
  weekstudy:()=>{const n=weekQ().n,u=unitOf(n);P.last=u;save();S.u=u;go('study',{i:n-U[u].a,rev:false})},
  weekclass:()=>{const n=weekQ().n,u=unitOf(n);go('class',{cu:u,ci:n-U[u].a,crev:false})},
  sctoggle:()=>{P.score=P.score||{a:0,b:0,on:false};P.score.on=!P.score.on;save();render()},
  sc:b=>{P.score=P.score||{a:0,b:0,on:true};const t=b.dataset.t;P.score[t]=Math.max(0,P.score[t]+(+b.dataset.v));save();render();if(+b.dataset.v>0){const l=document.querySelector('.class-lumi .lumi');if(l){l.outerHTML=lumiSVG('cheer');document.querySelector('.class-lumi .lumi').classList.add('hop')}}},
  sczero:()=>{P.score={a:0,b:0,on:true};save();render()},
  speakT:()=>{const t=TEXTS[S.t];speak(t.list?t.list.map((x,i)=>(i+1)+'. '+x).join(' '):t.body)}
};
app.addEventListener('click',e=>{const b=e.target.closest('[data-act]');if(!b||b.disabled)return;const f=ACT[b.dataset.act];if(f)f(b)});
app.addEventListener('change',e=>{if(e.target.id==='cu'){S.cu=+e.target.value;S.ci=0;S.crev=false;render()}});
document.addEventListener('keydown',e=>{
  if(S.v==='class'){if(e.target.tagName==='SELECT')return;
    if(e.key===' '||e.key==='Enter'){e.preventDefault();ACT.crev()}
    else if(e.key==='ArrowRight')ACT.cnext();else if(e.key==='ArrowLeft')ACT.cprev();else if(e.key.toLowerCase()==='s')ACT.crand();}
  else if(S.v==='study'){if(e.key==='ArrowRight'&&S.i<nums(S.u).length-1)ACT.snext();else if(e.key==='ArrowLeft'&&S.i>0)ACT.sprev();else if(e.key===' '&&!S.rev){e.preventDefault();ACT.reveal()}}
});
try{speechSynthesis.getVoices()}catch(e){}
render();
