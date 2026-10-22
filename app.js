/* ===== Lumi Catecismos — Breve Catecismo, Catecismo Maior e Confissão de Fé ===== */
const app=document.getElementById('app');
const KEY='lumi-catecismo-v1';

/* ===== livros =====
   Cada livro vira uma lista de itens {q, a, r, label} e uma lista de lições {t, a, b}.
   No Breve e no Maior o item é pergunta e resposta; na Confissão, cada seção de um capítulo. */
const BOOKS={};
(function(){
  BOOKS.breve={id:'breve',name:'Breve Catecismo',full:'Breve Catecismo de Westminster',kind:'qa',
    tag:'Para toda a família',hash:'breve',color:'#215732',
    sub:'107 perguntas e respostas para aprender juntos, em casa e na igreja.',
    items:Q.map((x,i)=>({q:x[0],a:x[1],r:x[2],label:'Pergunta '+(i+1)})),units:U};
  BOOKS.maior={id:'maior',name:'Catecismo Maior',full:'Catecismo Maior de Westminster',kind:'qa',
    tag:'Para aprofundar o estudo',hash:'maior',color:'#7b2d35',
    sub:'196 perguntas e respostas para estudar a fé com mais profundidade.',
    items:QM.map((x,i)=>({q:x[0],a:x[1],r:x[2],label:'Pergunta '+(i+1)})),units:UM};
  const items=[],units=[];
  CF.forEach(c=>{const a=items.length+1;
    c.secs.forEach(s=>items.push({q:c.t,a:s[1],r:'',label:`Capítulo ${c.n} · Seção ${s[0]}`,ch:c.n,sec:s[0]}));
    units.push({t:c.t,a,b:items.length,ch:c.n});});
  BOOKS.conf={id:'conf',name:'Confissão de Fé',full:'Confissão de Fé de Westminster',kind:'conf',
    tag:'A fé que confessamos',hash:'confissao',color:'#1f5068',
    sub:'33 capítulos para conhecer, com reverência, a fé que a Igreja confessa.',items,units};
})();
const ORDER=['breve','maior','conf'];
let B=BOOKS.breve;

/* ===== progresso (salvo no aparelho) ===== */
let P={books:{},days:{},lastDay:null,lastBook:null,score:null};
try{const r=localStorage.getItem(KEY);if(r){const o=JSON.parse(r);
  if(o.m&&!o.books){o.books={breve:{m:o.m,seen:o.seen||{},last:o.last??null}};delete o.m;delete o.seen;delete o.last;o.lastBook='breve'}
  P=Object.assign(P,o);}}catch(e){}
P.books=P.books||{};P.days=P.days||{};
function save(){try{localStorage.setItem(KEY,JSON.stringify(P))}catch(e){}}
function bp(id){id=id||B.id;return P.books[id]=P.books[id]||{m:{},seen:{},last:null}}

/* ===== utilidades ===== */
const esc=s=>String(s).replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const range=(a,b)=>Array.from({length:b-a+1},(_,i)=>a+i);
const it=n=>B.items[n-1];
const all=()=>range(1,B.items.length);
const nums=u=>u<0?all():range(B.units[u].a,B.units[u].b);
const shuffle=a=>{a=a.slice();for(let i=a.length-1;i>0;i--){const j=Math.floor(Math.random()*(i+1));[a[i],a[j]]=[a[j],a[i]]}return a};
const pick=a=>a[Math.floor(Math.random()*a.length)];
const norm=w=>w.normalize('NFD').replace(/[̀-ͯ]/g,'').toLowerCase().replace(/[^a-z0-9-]/g,'');
const bare=w=>w.replace(/^[“”"(]+|[“”")\.,;:!?]+$/g,'');
const stars=(n,id)=>bp(id).m[n]||0;
const unitOf=n=>B.units.findIndex(u=>n>=u.a&&n<=u.b);
const pctOf=(id)=>{const b=BOOKS[id],m=bp(id).m;let s=0;for(let n=1;n<=b.items.length;n++)s+=m[n]||0;return Math.round(s/(b.items.length*3)*100)};
const pct=list=>Math.round(list.reduce((s,n)=>s+stars(n),0)/(list.length*3)*100);
const isConf=()=>B.kind==='conf';
const itemWord=()=>isConf()?'Seção':'Pergunta';
const unitWord=()=>isConf()?'Capítulo':'Lição';
const unitNum=u=>isConf()?B.units[u].ch:u+1;
const STOP=new Set("que para como pela pelo pelas pelos nossa nosso nossos nossas todas todos toda todo mesmo sobre entre aquele aqueles aquela aquelas tambem quando porque dele dela delas deles desta deste destas destes mais isto isso seus suas sua seu cada esta este estas estes nesta neste muito sendo assim pois qual quais nele nela nelas neles numa outro outros outra outras ainda aos das dos quanto quanto".split(' '));
function trunc(s,m){return s.length>m?s.slice(0,m).replace(/\s+\S*$/,'')+'…':s}
/* textos longos (Maior e Confissão): nos jogos usamos o começo, até o fim de uma frase */
function gameText(a){
  const w=a.split(/\s+/);if(w.length<=80)return {t:a,cut:false};
  let k=0;for(let i=44;i<Math.min(w.length,80);i++){if(/[.;:]$/.test(w[i])){k=i+1;break}}
  if(!k)k=60;return {t:w.slice(0,k).join(' ').replace(/[;:,]$/,''),cut:true};
}

/* ===== tom de cada livro ===== */
const TONE={
  breve:{praise:['Muito bem!','Isso mesmo!','Correto!','Boa memória!','Excelente!'],meh:'Quase!',mehOk:'Quase perfeito!',sad:'Vamos revisar'},
  maior:{praise:['Correto.','Muito bem.','Exato.','Bom estudo.','Resposta firme.'],meh:'Quase.',mehOk:'Quase perfeito.',sad:'Vale revisar'},
  conf:{praise:['Correto.','Fiel ao texto.','Muito bem.','Exato.','Assim confessamos.'],meh:'Quase.',mehOk:'Quase perfeito.',sad:'Vale reler o texto'}
};
const mood=m=>(isConf()&&m==='cheer')?'happy':m;

function flameSVG(on){return `<svg viewBox="0 0 12 16" aria-hidden="true"><path class="${on?'on':'off'}" d="M6 15C2.5 15 1 12.5 1.6 9.8 2.2 7.2 4.6 6 5 1c2.6 2.3 5.4 5.4 5.4 9 0 3-1.8 5-4.4 5z"/></svg>`}
function flamesRow(n){const s=stars(n);return `<span class="flames" aria-label="${s} de 3">${[0,1,2].map(i=>flameSVG(i<s)).join('')}</span>`}

function bushSVG(){
  const fl=(x,h,w,l,base)=>`M${x} ${base} C${x-w} ${base-h*.35} ${x-w*.55+l} ${base-h*.78} ${x+l} ${base-h} C${x+w*.55+l} ${base-h*.72} ${x+w} ${base-h*.35} ${x} ${base}Z`;
  const outer=[[20,30,10,-4],[34,46,11,-3],[48,58,12,-1],[61,66,12,0],[74,58,12,1],[88,46,11,3],[102,30,10,4]];
  const inner=[[34,24,5,-2],[48,32,6,-1],[61,38,6,0],[74,32,6,1],[88,24,5,2]];
  return `<svg class="bush" viewBox="0 0 122 92" aria-hidden="true">${outer.map(f=>`<path class="f1" d="${fl(f[0],f[1],f[2],f[3],78)}"/>`).join('')}${inner.map(f=>`<path class="f2" d="${fl(f[0],f[1],f[2],f[3],78)}"/>`).join('')}<rect class="bar" x="16" y="84" width="90" height="4" rx="2"/></svg>`;
}

/* ===== Lumi: humores e reações =====
   moods: idle, happy, cheer, meh, sad, think, sleep */
function lumiSVG(mood='idle',attrs=''){
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
  return `<svg class="lumi" data-mood="${mood}" ${attrs} viewBox="-2 -6 102 82" aria-hidden="true" style="color:var(--ink,var(--fg))">
  <g class="body"><path d="M30 55v12M42 57v12M56 57v12" stroke="currentColor" stroke-width="3.4" stroke-linecap="round"/>
  <path fill="var(--wool)" stroke="currentColor" stroke-width="2.2" d="M20 42c-8 0-11-8-7-13 0-8 9-11 14-8 3-7 13-8 17-3 6-4 15-1 16 5 7 0 11 7 8 12 4 6 0 13-7 13-1 6-9 9-14 5-4 5-13 5-16 0-7 3-13-1-11-11z"/></g>
  <g class="head"><ellipse class="ear" cx="61" cy="25" rx="7" ry="3.4" transform="rotate(-28 61 25)" fill="var(--face)"/>
  <ellipse cx="70" cy="34" rx="10.5" ry="12.5" fill="var(--face)"/>
  <ellipse cx="80" cy="27" rx="6" ry="3" transform="rotate(25 80 27)" fill="var(--face)"/>
  ${eyes}${cheeks}${mouth}${extra}
  <path class="flame" d="M60 14c2-4 1-7 0-9 3 2 6 5 5 9-1 2-3 2-5 0z" fill="var(--gold)"/></g>
  </svg>`;
}
function lumiReact(m,ms=850){
  m=mood(m);const el=document.querySelector('.lumi-live');if(!el)return;
  el.innerHTML=lumiSVG(m);el.firstElementChild.classList.add(m==='sad'?'shake':m==='meh'?'tilt':'hop');
  clearTimeout(lumiReact.t);
  lumiReact.t=setTimeout(()=>{const e=document.querySelector('.lumi-live');if(e&&S.v==='game'&&!S.g.done)e.innerHTML=lumiSVG('think')},ms);
}

/* ===== a Lumi brincando com os três livros (capa) ===== */
function booksScene(){
  const book=(id,x,y,w,h,label,cls='',left=false)=>`<g class="bk ${cls}" data-act="openbook" data-b="${id}" role="button" tabindex="0" aria-label="Abrir ${BOOKS[id].name}">
    <rect x="${x}" y="${y}" width="${w}" height="${h}" rx="4" fill="${BOOKS[id].color}"/>
    <rect x="${x}" y="${y}" width="${w}" height="3" rx="1.5" fill="#fff" opacity=".18"/>
    <rect x="${x+9}" y="${y}" width="2.4" height="${h}" fill="#e0ad4a" opacity=".9"/><rect x="${x+w-11.4}" y="${y}" width="2.4" height="${h}" fill="#e0ad4a" opacity=".9"/>
    <text x="${left?x+15:x+w/2}" y="${y+h/2+3.6}" text-anchor="${left?'start':'middle'}" fill="#f6ecd6" font-size="10" font-weight="700" letter-spacing="1.4" font-family="var(--f-display)">${label}</text></g>`;
  return `<svg class="scene" viewBox="0 0 330 200" aria-label="A Lumi brincando com os três livros">
    <ellipse cx="190" cy="186" rx="130" ry="9" fill="#000" opacity=".22"/>
    ${book('maior',96,150,190,30,'CATECISMO MAIOR')}
    ${book('conf',110,121,164,29,'CONFISSÃO','bk-conf',true)}
    <g class="bk bk-breve" data-act="openbook" data-b="breve" role="button" tabindex="0" aria-label="Abrir Breve Catecismo">
      <rect x="292" y="86" width="30" height="94" rx="4" fill="${BOOKS.breve.color}"/>
      <rect x="292" y="95" width="30" height="2.4" fill="#e0ad4a"/><rect x="292" y="168" width="30" height="2.4" fill="#e0ad4a"/>
      <text transform="rotate(-90 307 133)" x="307" y="136.5" text-anchor="middle" fill="#f6ecd6" font-size="9.5" font-weight="700" letter-spacing="1.2" font-family="var(--f-display)">BREVE</text></g>
    <g class="page"><path d="M40 168c10-8 22-8 32 0-10-3-22-3-32 0z" fill="#f6ecd6"/><path d="M40 168v-2c10-7 22-7 32 0v2" fill="none" stroke="#e0ad4a" stroke-width="1"/></g>
    <g class="lumi-on-books">${lumiSVG('happy','x="160" y="38" width="130" height="104"')}</g>
    <g class="notes" fill="#e0ad4a"><path d="M262 40l1.4 3 3 1.4-3 1.4-1.4 3-1.4-3-3-1.4 3-1.4z"/><path d="M84 92l1 2.2 2.2 1-2.2 1-1 2.2-1-2.2-2.2-1 2.2-1z"/></g>
  </svg>`;
}

/* ===== datas, semana, saudação ===== */
const today=()=>{const d=new Date();return d.getFullYear()+'-'+String(d.getMonth()+1).padStart(2,'0')+'-'+String(d.getDate()).padStart(2,'0')};
function markDay(){P.days[today()]=1;P.lastDay=today();P.lastBook=B.id}
function daysSince(day){if(!day)return Infinity;const [y,m,d]=day.split('-').map(Number);return Math.round((new Date(new Date().toDateString())-new Date(y,m-1,d))/864e5)}
function weekQ(b=B){
  // muda todo domingo; a semana 1 começou em 4/jan/2026; depois do último item o ciclo recomeça
  const base=new Date(2026,0,4),now=new Date(new Date().toDateString());
  const w=Math.floor((now-base)/(7*864e5)),N=b.items.length;const n=((w%N)+N)%N+1;
  const start=new Date(base.getTime()+w*7*864e5),end=new Date(start.getTime()+6*864e5);
  const f=d=>d.toLocaleDateString('pt-BR',{day:'numeric',month:'short'}).replace('.','');
  return {n,label:`${f(start)} a ${f(end)}`};
}
function greet(){const h=new Date().getHours();return h<12?'Bom dia':h<18?'Boa tarde':'Boa noite'}

/* falas da Lumi: na capa geral e em cada livro (com o tom de cada um) */
function hubLine(){
  const ds=daysSince(P.lastDay),lb=P.lastBook&&BOOKS[P.lastBook];
  const any=ORDER.some(id=>Object.keys(bp(id).m).length);
  if(!any)return {mood:'happy',html:`${greet()}! Eu sou a Lumi. Trouxe três livros para estudarmos juntos: o <b>Breve Catecismo</b>, o <b>Catecismo Maior</b> e a <b>Confissão de Fé</b>. Toque em um deles!`};
  if(ds>=4)return {mood:'sleep',html:`Zzz… ah, ${greet().toLowerCase()}! Fiquei cuidando dos livros esses ${ds} dias. Vamos voltar ao ${lb?lb.name:'estudo'}?`};
  if(ds===0)return {mood:'cheer',html:`Você já estudou hoje! Quer continuar no <b>${lb?lb.name:'Breve Catecismo'}</b> ou abrir outro livro?`};
  return {mood:'idle',html:`${greet()}! Da última vez você estava no <b>${lb?lb.name:'Breve Catecismo'}</b>. Vamos continuar?`};
}
function lumiLine(){
  const id=B.id;
  if(S.poke){const n=S.poke.n,x=it(n);
    if(!S.poke.rev){
      if(id==='conf')return {mood:'think',html:`${x.label}, <b>${esc(x.q)}</b>. Lembra o que diz?<br><button class="linkbtn" data-act="pokerev">Mostrar o texto</button>`};
      return {mood:'think',html:`${id==='breve'?'Você lembra a':'Responda:'} pergunta ${n}?<br><b>${esc(x.q)}</b><br><button class="linkbtn" data-act="pokerev">Mostrar resposta</button>`};}
    return {mood:mood('cheer'),html:`${id==='conf'?'':`<b>${n}.</b> `}${esc(trunc(x.a,200))}<br><button class="linkbtn" data-act="poke">${id==='conf'?'Outra seção':'Outra pergunta'}</button>`};}
  const learned=all().filter(n=>stars(n)>0).length,mastered=all().filter(n=>stars(n)>=3).length;
  const wk=weekQ(),last=bp().last!=null&&B.units[bp().last]?bp().last:0,ds=daysSince(P.lastDay);
  const L={
    breve:{first:`${greet()}! Vamos aprender o Breve Catecismo juntos? Toque em mim para uma pergunta surpresa.`,
      day:`Você já estudou hoje! ${mastered?`Já são ${mastered} pergunta${mastered>1?'s':''} dominada${mastered>1?'s':''}.`:'Continue que as chamas vão acender.'}`,
      week:`${greet()}! A pergunta da semana é a ${wk.n}. Vamos estudar?`},
    maior:{first:`${greet()}. O Catecismo Maior aprofunda cada verdade, com respostas mais longas. Vamos devagar, uma lição por vez.`,
      day:`Bom estudo hoje. ${mastered?`${mastered} pergunta${mastered>1?'s':''} já dominada${mastered>1?'s':''}.`:'Cada resposta firmada vale a pena.'}`,
      week:`${greet()}. Pergunta da semana: a ${wk.n}. Que tal estudá-la com calma?`},
    conf:{first:`${greet()}. A Confissão de Fé reúne, em 33 capítulos, a fé que a Igreja confessa. Comece pelo capítulo 1, sobre as Escrituras.`,
      day:`Que bom ler a Confissão hoje. ${mastered?`${mastered} seç${mastered>1?'ões':'ão'} já bem guardada${mastered>1?'s':''}.`:'Leia com calma; o texto é rico.'}`,
      week:`${greet()}. A seção da semana é do ${it(wk.n).label.split(' · ')[0].toLowerCase()}. Vamos ler juntos?`}
  }[id];
  if(!learned)return {mood:'happy',html:L.first};
  if(ds>=4)return {mood:'sleep',html:`Zzz… ah, ${greet().toLowerCase()}! Faz ${ds} dias que não estudamos. Que tal revisar ${isConf()?'o capítulo':'a lição'} ${unitNum(last)}?`};
  if(ds===0)return {mood:'happy',html:L.day};
  return {mood:'idle',html:L.week};
}

/* ===== fala ===== */
function speak(text){
  try{const s=window.speechSynthesis;s.cancel();const u=new SpeechSynthesisUtterance(text.replace(/[“”]/g,''));u.lang='pt-BR';u.rate=.95;
  const v=s.getVoices().find(v=>/^pt/i.test(v.lang));if(v)u.voice=v;s.speak(u);}catch(e){}
}

/* ===== estado e navegação ===== */
const S={v:'hub'};
function setBook(id){B=BOOKS[id]||BOOKS.breve;document.documentElement.dataset.book=B.id}
function go(v,extra){
  document.querySelectorAll('.confetti').forEach(c=>c.remove());
  Object.assign(S,{v},extra||{});try{speechSynthesis.cancel()}catch(e){};
  if(v==='hub'||v==='text')document.documentElement.dataset.book='hub';else document.documentElement.dataset.book=B.id;
  try{history.replaceState(null,'',v==='hub'?location.pathname:location.pathname+'#'+B.hash)}catch(e){}
  render();window.scrollTo(0,0);
}
function topbar(title,back,right){
  return `<div class="topbar"><div class="wrap"><button class="back" data-act="${back}" aria-label="Voltar">‹ Voltar</button><span class="tt">${esc(title)}</span>${right?`<span class="count">${right}</span>`:''}</div></div>`;
}

/* ===== capa geral: Lumi Catecismos ===== */
function vHub(){
  const line=hubLine();
  return `
  <div class="band hub"><div class="wrap hero">
    <div class="hero-text"><p class="eyebrow">Westminster · em jogos</p>
    <h1 class="roll" aria-label="Lumi Catecismos">${rollHTML('Lumi Catecismos')}</h1>
    <p>O Breve Catecismo, o Catecismo Maior e a Confissão de Fé, para aprender em casa e ensinar na igreja.</p></div>
    <div class="scene-wrap">${booksScene()}</div>
    <div class="bubble hub-bubble" aria-live="polite">${line.html}</div>
  </div></div>
  <main class="wrap">
    <section>
      <div class="sec-h"><h2>Os três livros</h2><span class="ls">Toque para abrir</span></div>
      <div class="shelf">${ORDER.map(id=>{const b=BOOKS[id],p=pctOf(id),wk=weekQ(b);
        return `<button class="bookcard" data-act="openbook" data-b="${id}" style="--bc:${b.color}">
          <span class="spine" aria-hidden="true"></span>
          <span class="bc-body"><span class="eyebrow">${b.tag}</span><b>${b.name}</b>
          <span class="ls">${id==='conf'?`33 capítulos · ${b.items.length} seções`:`${b.items.length} perguntas · ${b.units.length} lições`}</span>
          <span class="bc-week">${id==='conf'?'Seção':'Pergunta'} da semana: ${id==='conf'?esc(b.items[wk.n-1].label):wk.n}</span>
          <span class="mini"><i style="width:${p}%"></i></span></span>
          <span class="bc-pct">${p}%</span></button>`}).join('')}</div>
    </section>
    <section>
      <div class="sec-h"><h2>Na igreja</h2></div>
      <div class="tools">
        <button class="tool primary" data-act="class"><b>Modo Classe</b><span>Projetar perguntas de qualquer livro, revelar respostas e marcar pontos por equipe.</span></button>
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
    <p class="foot">O progresso de cada livro fica salvo neste aparelho.</p>
  </main>`;
}

/* ===== capa de cada livro ===== */
function vBook(){
  const p=pct(all()),learned=all().filter(n=>stars(n)>0).length;
  const days=Object.keys(P.days||{}).length;
  const last=bp().last!=null&&B.units[bp().last]?bp().last:null;
  const wk=weekQ(),line=lumiLine(),w=it(wk.n);
  return `
  <div class="band"><div class="wrap hero">
    <button class="back-hub" data-act="home">‹ Lumi Catecismos</button>
    <div class="hero-text"><p class="eyebrow">${B.tag}</p>
    <h1 class="roll" aria-label="${B.full}">${rollHTML(B.full)}</h1>
    <p>${B.sub}</p></div>
    <div class="lumi-row">
      <div class="bubble" aria-live="polite">${line.html}</div>
      <button class="lumi-stage" data-act="poke" aria-label="Pedir uma ${isConf()?'seção':'pergunta'} surpresa à Lumi">${bushSVG()}${lumiSVG(line.mood)}</button>
    </div>
    <div class="hero-stats"><span><b>${p}%</b> do livro</span><span><b>${learned}</b> de ${B.items.length} praticad${isConf()?'as':'as'}</span><span><b>${days}</b> dia${days===1?'':'s'} de estudo</span></div>
    <div class="overall" title="${p}% concluído"><i style="width:${p}%"></i></div>
  </div></div>
  <main class="wrap">
    <section class="week">
      <div class="week-head"><span class="eyebrow">${itemWord()} da semana · ${wk.label}</span><span class="week-n">${isConf()?`${w.ch}.${w.sec}`:wk.n}</span></div>
      <p class="week-q">${esc(isConf()?`${w.label.split(' · ')[0]}: ${w.q}`:w.q)}</p>
      <div class="row"><button class="btn solid" data-act="weekstudy">${isConf()?'Ler':'Estudar'}</button><button class="btn" data-act="weekclass">Projetar na classe</button></div>
    </section>
    ${last!=null?`<button class="continue" data-act="unit" data-u="${last}"><span class="cont-n">${unitNum(last)}</span><span><span class="eyebrow">Continuar</span><b>${esc(B.units[last].t)}</b><span class="ls">${unitRange(last)} · ${pct(nums(last))}% dominado</span></span><span class="chev">›</span></button>`:''}
    <section>
      <div class="sec-h"><h2>${isConf()?'Capítulos':'Lições'}</h2><span class="ls">3 chamas = ${isConf()?'seção':'pergunta'} dominada</span></div>
      <ul class="lessons">${B.units.map((u,i)=>{const pp=pct(nums(i));return `<li><button class="lesson" data-act="unit" data-u="${i}">
        <span class="num">${unitNum(i)}</span>
        <span style="min-width:0"><span class="lt">${esc(u.t)}</span><span class="ls">${unitRange(i)}</span><span class="mini"><i style="width:${pp}%"></i></span></span>
        <span class="chev">›</span></button></li>`}).join('')}</ul>
    </section>
    <section>
      <div class="sec-h"><h2>Na igreja</h2></div>
      <div class="tools">
        <button class="tool primary" data-act="class"><b>Modo Classe</b><span>Projetar, revelar e marcar pontos por equipe.</span></button>
        <button class="tool" data-act="review"><b>Revisão geral</b><span>8 ${isConf()?'seções':'perguntas'} sorteadas de todo o livro.</span></button>
      </div>
    </section>
    <p class="foot">O progresso fica salvo neste aparelho.</p>
  </main>`;
}
function unitRange(i){const u=B.units[i];return isConf()?`${u.b-u.a+1} seç${u.b-u.a?'ões':'ão'}`:`Perguntas ${u.a}–${u.b}`}

function vUnit(){
  const u=B.units[S.u], list=nums(S.u);
  return topbar(`${unitWord()} ${unitNum(S.u)}`,'bookhome',pct(list)+'%')+`
  <main class="wrap">
    <div><p class="eyebrow">${B.name} · ${unitWord()} ${unitNum(S.u)} · ${unitRange(S.u)}</p><h1 style="font-size:1.8rem;margin-top:4px">${esc(u.t)}</h1></div>
    <div class="tools">
      <button class="tool primary" data-act="study" data-i="0"><b>${isConf()?'Ler':'Estudar'}</b><span>${isConf()?'Ler e ouvir cada seção do capítulo.':'Ler, ouvir e revelar cada resposta.'}</span></button>
      <button class="tool" data-act="play" data-mode="quiz"><b>Quiz</b><span>${isConf()?'De qual capítulo é este trecho?':'Escolha a resposta certa.'}</span></button>
      <button class="tool" data-act="play" data-mode="complete"><b>Completar</b><span>Encaixe as palavras que faltam.</span></button>
      <button class="tool" data-act="play" data-mode="build"><b>Montar</b><span>Coloque os trechos na ordem.</span></button>
      <button class="tool" data-act="play" data-mode="mix"><b>Desafio</b><span>Tudo misturado, para fixar.</span></button>
    </div>
    <section>
      <div class="sec-h"><h2>${isConf()?'Seções':'Perguntas'}</h2><span class="ls">3 chamas = dominada</span></div>
      <ul class="qlist">${list.map((n,i)=>`<li><button class="qrow" data-act="study" data-i="${i}"><span class="n">${isConf()?it(n).sec:n}</span><span>${esc(isConf()?trunc(it(n).a,90):it(n).q)}</span>${flamesRow(n)}</button></li>`).join('')}</ul>
    </section>
  </main>`;
}

function vStudy(){
  const list=nums(S.u), n=list[S.i], x=it(n);
  return topbar(B.units[S.u].t,'backunit',`${S.i+1}/${list.length}`)+`
  <main class="wrap">
    <article class="card">
      <div class="qnum">${x.label}</div>
      <div class="qtext">${esc(x.q)}</div>
      <div class="atext ${S.rev?'':'hidden'}" ${S.rev?'':'aria-hidden="true"'}>${esc(x.a)}</div>
      <div class="row">
        ${S.rev?'':`<button class="btn solid" data-act="reveal">${isConf()?'Mostrar o texto':'Mostrar resposta'}</button>`}
        <button class="btn" data-act="speak">▶ Ouvir</button>
      </div>
      ${x.r?`<div class="refs"><b>Referências:</b> ${esc(x.r)}</div>`:''}
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
  out=out.reduce((acc,c)=>{if(acc.length&&c.split(' ').length<2)acc[acc.length-1]+=' '+c;else acc.push(c);return acc},[]);
  while(out.length>7){let best=0,bl=1e9;for(let i=0;i<out.length-1;i++){const l=out[i].length+out[i+1].length;if(l<bl){bl=l;best=i}}out.splice(best,2,out[best]+' '+out[best+1]);}
  if(out.length<3){const w=a.split(/\s+/);const sz=Math.ceil(w.length/3);out=[];for(let i=0;i<w.length;i+=sz)out.push(w.slice(i,i+sz).join(' '));}
  return out;
}
function candidates(n){
  const x=it(n),qs=new Set(x.q.split(/\s+/).map(norm));
  const words=gameText(x.a).t.split(/\s+/);
  return {words,c:words.map((w,i)=>({i,k:norm(w)})).filter(o=>o.k.length>=4&&!STOP.has(o.k)&&!qs.has(o.k))};
}
function setupItem(){
  const g=S.g,itm=g.items[g.i],n=itm.n,x=it(n);
  g.done=false;g.miss=0;g.correct=null;g.mood=null;
  if(itm.mode==='complete'){
    const {words,c}=candidates(n);
    const k=Math.min(c.length, words.length<15?2:words.length<35?3:4);
    if(k<1){itm.mode='quiz';return setupItem();}
    const seenK=new Set();const chosen=[];
    for(const o of shuffle(c)){if(chosen.length>=k)break;if(!seenK.has(o.k)){seenK.add(o.k);chosen.push(o)}}
    chosen.sort((p,q)=>p.i-q.i);
    const others=shuffle(all().filter(m=>m!==n)).slice(0,6).flatMap(m=>{const cc=candidates(m);return cc.c.map(o=>bare(cc.words[o.i]))});
    const distract=[];for(const w of shuffle(others)){if(distract.length>=2)break;if(!seenK.has(norm(w))&&!distract.some(d=>norm(d)===norm(w)))distract.push(w)}
    g.st={words,cut:gameText(x.a).cut,blanks:chosen.map(o=>o.i),filled:0,bank:shuffle([...chosen.map(o=>bare(words[o.i])),...distract]).map(w=>({w,used:false}))};
  } else if(itm.mode==='build'){
    const gt=gameText(x.a),ch=chunksOf(gt.t);
    g.st={chunks:ch,cut:gt.cut,order:shuffle(ch.map((_,i)=>i)),placed:[],used:new Set()};
    if(g.st.order.every((v,i)=>v===i)&&ch.length>1)g.st.order.reverse();
  } else if(isConf()){
    // Confissão: mostra um trecho e pergunta de qual capítulo ele é
    const chs=B.units.map(u=>u.ch).filter(c=>c!==x.ch);
    g.st={opts:shuffle([x.ch,...shuffle(chs).slice(0,3)]),chosen:null,excerpt:gameText(x.a).t.split(/\s+/).slice(0,34).join(' ')};
  } else {
    const list=g.pool.filter(m=>m!==n);
    const wrong=shuffle(list.length>=3?list:all().filter(m=>m!==n)).slice(0,3);
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
const misses=g=>`${g.miss} tentativa${g.miss>1?'s':''} errada${g.miss>1?'s':''}`;

function vGame(){
  const g=S.g,itm=g.items[g.i],n=itm.n,x=it(n),T=TONE[B.id];
  const dots=g.items.map((_,i)=>`<i class="${i<g.i?'d':i===g.i?'c':''}"></i>`).join('');
  const confQuiz=isConf()&&itm.mode==='quiz';
  let body='';
  if(itm.mode==='quiz'&&confQuiz){
    body=`<blockquote class="excerpt">“${esc(g.st.excerpt)}…”</blockquote><p class="prompt-label">De qual capítulo é este trecho?</p><div class="opts">${g.st.opts.map(c=>{
      let cls='';if(g.done){if(c===x.ch)cls='right';else if(c===g.st.chosen)cls='wrong'}
      const u=B.units.find(u=>u.ch===c);
      return `<button class="opt ${cls}" data-act="qopt" data-m="${c}" ${g.done?'disabled':''}><b>Capítulo ${c}</b> · ${esc(u.t)}</button>`}).join('')}</div>`;
  } else if(itm.mode==='quiz'){
    body=`<p class="prompt-label">Qual é a resposta?</p><div class="opts">${g.st.opts.map(m=>{
      let cls='';if(g.done){if(m===n)cls='right';else if(m===g.st.chosen)cls='wrong'}
      return `<button class="opt ${cls}" data-act="qopt" data-m="${m}" ${g.done?'disabled':''}>${esc(trunc(it(m).a,170))}</button>`}).join('')}</div>`;
  } else if(itm.mode==='complete'){
    const st=g.st;
    const txt=st.words.map((w,i)=>{const b=st.blanks.indexOf(i);if(b<0)return esc(w);
      const lead=(w.match(/^[“”"(]+/)||[''])[0],trail=(w.match(/[“”")\.,;:!?]+$/)||[''])[0];
      const filled=b<st.filled;const cur=b===st.filled&&!g.done;
      return `${esc(lead)}<span class="blank ${filled?'ok':''} ${cur?'cur':''}">${filled?esc(bare(w)):'·····'}</span>${esc(trail)}`}).join(' ')+(st.cut?' <span class="cont">(continua…)</span>':'');
    body=`<p class="prompt-label">Complete ${isConf()?'o texto':'a resposta'} tocando nas palavras na ordem</p><div class="card"><div class="fill">${txt}</div></div>
      ${g.done?'':`<div class="bank">${st.bank.map((b,k)=>`<button class="chip ${b.used?'used':''}" data-act="cpick" data-k="${k}" ${b.used?'disabled':''}>${esc(b.w)}</button>`).join('')}</div>`}
      ${g.miss?`<p class="miss">${misses(g)}</p>`:''}`;
  } else {
    const st=g.st;
    body=`<p class="prompt-label">Monte ${isConf()?'o início do texto':'a resposta'} tocando nos trechos na ordem</p>
      <div class="built">${st.placed.map(i=>`<span>${esc(st.chunks[i])} </span>`).join('')}</div>
      ${g.done?'':`<div class="bank" style="flex-direction:column;align-items:stretch">${st.order.filter(i=>!st.used.has(i)).map(i=>`<button class="chip long" data-act="bpick" data-k="${i}">${esc(st.chunks[i])}</button>`).join('')}</div>`}
      ${g.miss?`<p class="miss">${misses(g)}</p>`:''}`;
  }
  const head=confQuiz?`<div class="qnum">${B.name} · Quiz</div><div class="qtext" style="margin-top:6px">${g.done?esc(x.label+': '+x.q):'Reconheça o capítulo'}</div>`
    :`<div class="qnum">${x.label} · ${MODE_NAME[itm.mode]}</div><div class="qtext" style="margin-top:6px">${esc(x.q)}</div>`;
  const fb=g.done?`<div class="feedback ${g.mood==='sad'?'bad':g.mood==='meh'?'meh':''}"><div class="wrap"><div class="fb">
    <h3>${g.mood==='cheer'?pick(T.praise):g.mood==='meh'?(g.correct?T.mehOk:T.meh):T.sad}</h3>
    ${g.mood==='cheer'&&itm.mode!=='quiz'?'':`<p>${isConf()?`<b>${esc(x.label)}.</b> `:`<b>${n}.</b> `}${esc(x.a)}</p>`}
    ${x.r?`<p class="ls">${esc(x.r)}</p>`:''}
    <div class="row"><button class="btn solid" data-act="cont">${g.i<g.items.length-1?'Continuar':'Ver resultado'}</button><button class="btn" data-act="speakA">▶ Ouvir</button></div>
  </div></div></div>`:'';
  return topbar(MODE_NAME[g.mode],'quit',`${g.i+1}/${g.items.length}`)+`
  <main class="wrap" style="padding-bottom:${g.done?'12px':'48px'}">
    <div class="dots">${dots}</div>
    <div class="qhead"><div style="min-width:0">${head}</div><div class="lumi-live">${lumiSVG(g.done?mood(g.mood):'think')}</div></div>
    ${body}
  </main>${fb}`;
}
function answered(ok){
  const g=S.g,n=g.items[g.i].n;g.done=true;g.correct=ok;g.mood=!g.miss?'cheer':g.miss===1?'meh':'sad';
  if(ok){g.ok++;bp().m[n]=Math.min(3,(bp().m[n]||0)+1)}
  bp().seen[n]=1;markDay();save();render();
  const f=document.querySelector('.feedback');if(f)f.scrollIntoView({block:'end',behavior:'smooth'});
}

function vResult(){
  const g=S.g,t=g.items.length,r=g.ok/t;
  const msg={breve:r===1?'Perfeito! Você sabe estas respostas.':r>=.6?'Muito bom. Mais uma rodada e fica firme.':'Vale estudar as respostas e tentar de novo.',
    maior:r===1?'Excelente. Todas as respostas firmes.':r>=.6?'Bom estudo. Mais uma rodada consolida.':'Vale reler as respostas com calma e tentar de novo.',
    conf:r===1?'Muito bem. Você conhece bem estes textos.':r>=.6?'Bom. Uma nova leitura deixa tudo mais claro.':'Vale reler o capítulo com calma e tentar de novo.'}[B.id];
  const md=mood(r>=.8?'cheer':r>=.5?'happy':'sad');
  return topbar('Resultado',g.back==='book'?'bookhome':'backunit','')+`
  <main class="wrap"><section class="card result">
    <div class="result-lumi">${lumiSVG(md)}</div>
    <div class="big">${g.ok}/${t}</div>
    <h2>${msg}</h2>
    <ul class="qlist" style="width:100%;text-align:left">${g.items.map(x=>`<li><div class="qrow" style="cursor:default"><span class="n">${isConf()?it(x.n).ch+'.'+it(x.n).sec:x.n}</span><span>${esc(isConf()?it(x.n).q:it(x.n).q)}</span>${flamesRow(x.n)}</div></li>`).join('')}</ul>
    <div class="row" style="justify-content:center"><button class="btn solid" data-act="again">Jogar de novo</button>${g.back==='book'?`<button class="btn" data-act="bookhome">Voltar ao livro</button>`:`<button class="btn" data-act="study" data-i="0">${isConf()?'Ler o capítulo':'Estudar a lição'}</button>`}</div>
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
  const list=nums(S.cu), n=list[S.ci], x=it(n);
  const sc=P.score||{a:0,b:0,on:false};
  return topbar('Modo Classe',S.from==='hub'?'home':'bookhome',`${S.ci+1}/${list.length}`)+`
  <div class="class">
    <div class="stage">
      <div class="class-top"><div class="qnum">${B.name} · ${x.label}${S.cu>=0&&!isConf()?' · Lição '+(S.cu+1):''}</div><div class="class-lumi">${lumiSVG(S.crev?'happy':'think')}</div></div>
      <div class="qtext">${esc(x.q)}</div>
      <div class="atext ${S.crev?'':'hidden'}">${esc(x.a)}</div>
      ${S.crev&&x.r?`<div class="refs">${esc(x.r)}</div>`:''}
    </div>
    ${sc.on?`<div class="score"><div class="wrap">
      <div class="team"><span>Equipe 1</span><button class="btn sm" data-act="sc" data-t="a" data-v="-1" aria-label="Tirar ponto da equipe 1">−</button><b>${sc.a}</b><button class="btn sm solid" data-act="sc" data-t="a" data-v="1" aria-label="Ponto para a equipe 1">+</button></div>
      <div class="team"><span>Equipe 2</span><button class="btn sm" data-act="sc" data-t="b" data-v="-1" aria-label="Tirar ponto da equipe 2">−</button><b>${sc.b}</b><button class="btn sm solid" data-act="sc" data-t="b" data-v="1" aria-label="Ponto para a equipe 2">+</button></div>
      <button class="btn sm" data-act="sczero">Zerar</button>
    </div></div>`:''}
    <div class="controls"><div class="wrap">
      <select id="cb" aria-label="Livro">${ORDER.map(id=>`<option value="${id}" ${B.id===id?'selected':''}>${BOOKS[id].name}</option>`).join('')}</select>
      <select id="cu" aria-label="${unitWord()}"><option value="-1" ${S.cu<0?'selected':''}>Livro inteiro</option>${B.units.map((u,i)=>`<option value="${i}" ${S.cu===i?'selected':''}>${unitWord()} ${unitNum(i)} · ${esc(trunc(u.t,46))}</option>`).join('')}</select>
      <button class="btn" data-act="cprev" ${S.ci===0?'disabled':''} aria-label="Anterior">‹</button>
      <button class="btn solid" data-act="crev">${S.crev?'Esconder':'Revelar'}</button>
      <button class="btn" data-act="cnext" ${S.ci>=list.length-1?'disabled':''} aria-label="Próxima">›</button>
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
  app.innerHTML=({hub:vHub,book:vBook,unit:vUnit,study:vStudy,game:vGame,result:vResult,class:vClass,text:vText}[S.v]||vHub)();
  if(S.v==='hub'||S.v==='book')initRoll();
  if(S.v==='result'&&S.g&&S.g.ok===S.g.items.length&&!S.g.party&&!isConf()){S.g.party=1;confetti()}
}

/* ===== Texto rolante das capas: letras rolam com atraso que nasce no centro ===== */
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
  cs.forEach(c=>{const d=+c.style.getPropertyValue('--d');c.firstChild.animate([{transform:'translateY(0)'},{transform:'translateY(-50%)'}],{duration:ROLL.duration*1000,delay:120+d*ROLL.speed*1000,easing:'cubic-bezier(.65,0,.25,1)',fill:'forwards'}).onfinish=function(){try{this.commitStyles()}catch(e){}this.cancel()}});
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
function openBook(id){setBook(id);P.lastBook=id;save();S.poke=null;go('book')}
const ACT={
  home:()=>{S.poke=null;go('hub')},
  openbook:b=>{const id=b.dataset.b;const sc=document.querySelector('.lumi-on-books .lumi');
    if(sc&&!(window.matchMedia&&matchMedia('(prefers-reduced-motion: reduce)').matches)){sc.classList.add('hop');setTimeout(()=>openBook(id),280)}else openBook(id)},
  bookhome:()=>{S.poke=null;go('book')},
  unit:b=>{const u=+b.dataset.u;bp().last=u;save();go('unit',{u})},
  backunit:()=>go('unit'),
  study:b=>go('study',{i:+(b.dataset.i||0),rev:false}),
  reveal:()=>{S.rev=true;bp().seen[nums(S.u)[S.i]]=1;markDay();save();render()},
  sprev:()=>go('study',{i:Math.max(0,S.i-1),rev:false}),
  snext:()=>go('study',{i:S.i+1,rev:false}),
  speak:()=>{const x=it(nums(S.u)[S.i]);speak(S.rev?x.q+'. '+x.a:x.q)},
  play:b=>startGame(b.dataset.mode,nums(S.u),'unit'),
  review:()=>startGame('mix',all(),'book'),
  quit:()=>go(S.g.back==='book'?'book':'unit'),
  again:()=>startGame(S.g.mode,S.g.pool,S.g.back),
  qopt:b=>{const m=+b.dataset.m,x=it(S.g.items[S.g.i].n);S.g.st.chosen=m;const ok=isConf()?m===x.ch:m===S.g.items[S.g.i].n;if(!ok)S.g.miss=1;answered(ok)},
  cpick:b=>{const g=S.g,st=g.st,k=+b.dataset.k,item=st.bank[k];
    const exp=norm(st.words[st.blanks[st.filled]]);
    if(norm(item.w)===exp){item.used=true;st.filled++;if(st.filled>=st.blanks.length)return answered(g.miss<=1);render();lumiReact('happy',700);}
    else{g.miss++;b.classList.remove('shake');void b.offsetWidth;b.classList.add('shake');const m=document.querySelector('.miss');if(m)m.textContent=misses(g);else render();lumiReact(g.miss>=2?'sad':'meh',900);}},
  bpick:b=>{const g=S.g,st=g.st,k=+b.dataset.k;const exp=st.chunks[st.placed.length];
    if(st.chunks[k]===exp){st.placed.push(k);st.used.add(k);if(st.placed.length===st.chunks.length)return answered(g.miss<=1);render();lumiReact('happy',700);}
    else{g.miss++;b.classList.remove('shake');void b.offsetWidth;b.classList.add('shake');const m=document.querySelector('.miss');if(m)m.textContent=misses(g);else render();lumiReact(g.miss>=2?'sad':'meh',900);}},
  cont:()=>{const g=S.g;g.i++;if(g.i>=g.items.length)return go('result');setupItem();go('game')},
  speakA:()=>{const x=it(S.g.items[S.g.i].n);speak(x.q+'. '+x.a)},
  class:()=>{const from=S.v==='hub'?'hub':'book';if(from==='hub')setBook(P.lastBook||'breve');go('class',{cu:bp().last!=null?bp().last:0,ci:0,crev:false,from})},
  crev:()=>{S.crev=!S.crev;render()},
  cprev:()=>{if(S.ci>0){S.ci--;S.crev=false;render()}},
  cnext:()=>{if(S.ci<nums(S.cu).length-1){S.ci++;S.crev=false;render()}},
  crand:()=>{const l=nums(S.cu);let i=S.ci;if(l.length>1)while(i===S.ci)i=Math.floor(Math.random()*l.length);S.ci=i;S.crev=false;render()},
  cspeak:()=>{const x=it(nums(S.cu)[S.ci]);speak(S.crev?x.q+'. '+x.a:x.q)},
  full:()=>{try{if(document.fullscreenElement)document.exitFullscreen();else document.documentElement.requestFullscreen().catch(()=>{})}catch(e){}},
  text:b=>go('text',{t:b.dataset.t}),
  speakT:()=>{const t=TEXTS[S.t];speak(t.list?t.list.map((x,i)=>(i+1)+'. '+x).join(' '):t.body)},
  poke:()=>{let n;do{n=pick(all())}while(S.poke&&n===S.poke.n);S.poke={n,rev:false};renderLumiRow('hop')},
  pokerev:()=>{if(S.poke){S.poke.rev=true;renderLumiRow('hop')}},
  weekstudy:()=>{const n=weekQ().n,u=unitOf(n);bp().last=u;save();S.u=u;go('study',{i:n-B.units[u].a,rev:false})},
  weekclass:()=>{const n=weekQ().n,u=unitOf(n);go('class',{cu:u,ci:n-B.units[u].a,crev:false,from:'book'})},
  sctoggle:()=>{P.score=P.score||{a:0,b:0,on:false};P.score.on=!P.score.on;save();render()},
  sc:b=>{P.score=P.score||{a:0,b:0,on:true};const t=b.dataset.t;P.score[t]=Math.max(0,P.score[t]+(+b.dataset.v));save();render();if(+b.dataset.v>0){const l=document.querySelector('.class-lumi .lumi');if(l){l.outerHTML=lumiSVG('cheer');document.querySelector('.class-lumi .lumi').classList.add('hop')}}},
  sczero:()=>{P.score={a:0,b:0,on:true};save();render()}
};
app.addEventListener('click',e=>{const b=e.target.closest('[data-act]');if(!b||b.disabled)return;const f=ACT[b.dataset.act];if(f)f(b)});
app.addEventListener('keydown',e=>{if((e.key==='Enter'||e.key===' ')&&e.target.matches&&e.target.matches('g[data-act]')){e.preventDefault();ACT[e.target.dataset.act](e.target)}});
app.addEventListener('change',e=>{
  if(e.target.id==='cu'){S.cu=+e.target.value;S.ci=0;S.crev=false;render()}
  if(e.target.id==='cb'){setBook(e.target.value);S.cu=-1;S.ci=0;S.crev=false;go('class')}
});
document.addEventListener('keydown',e=>{
  if(S.v==='class'){if(e.target.tagName==='SELECT')return;
    if(e.key===' '||e.key==='Enter'){e.preventDefault();ACT.crev()}
    else if(e.key==='ArrowRight')ACT.cnext();else if(e.key==='ArrowLeft')ACT.cprev();else if(e.key.toLowerCase()==='s')ACT.crand();}
  else if(S.v==='study'){if(e.key==='ArrowRight'&&S.i<nums(S.u).length-1)ACT.snext();else if(e.key==='ArrowLeft'&&S.i>0)ACT.sprev();else if(e.key===' '&&!S.rev){e.preventDefault();ACT.reveal()}}
});
try{speechSynthesis.getVoices()}catch(e){}

/* abre direto num livro pelo endereço: #breve, #maior ou #confissao */
function fromHash(){const h=(location.hash||'').slice(1);const id=ORDER.find(k=>BOOKS[k].hash===h);
  if(id){setBook(id);S.v='book';S.poke=null}else{S.v='hub'}
  document.documentElement.dataset.book=id||'hub';render();window.scrollTo(0,0)}
window.addEventListener('hashchange',fromHash);
/* mostra a barra de rolagem só enquanto a página rola */
let scrollT=0;window.addEventListener('scroll',()=>{document.documentElement.classList.add('scrolling');clearTimeout(scrollT);scrollT=setTimeout(()=>document.documentElement.classList.remove('scrolling'),900)},{passive:true});

/* barra de rolagem discreta: aparece ao rolar e some depois de um instante; dá para arrastar no computador */
(function(){
  const t=document.createElement('div');t.className='sb-thumb';t.setAttribute('aria-hidden','true');document.body.appendChild(t);
  let hideT=0,drag=null;
  function place(){const H=innerHeight,SH=document.documentElement.scrollHeight;
    if(SH<=H+2){t.style.display='none';return}t.style.display='';
    const h=Math.max(40,H*H/SH),top=(scrollY/(SH-H))*(H-h);t.style.height=h+'px';t.style.transform=`translateY(${top}px)`}
  function show(){place();t.classList.add('show');clearTimeout(hideT);hideT=setTimeout(()=>{if(!drag)t.classList.remove('show')},900)}
  addEventListener('scroll',show,{passive:true});addEventListener('resize',place);
  t.addEventListener('pointerdown',e=>{drag={y:e.clientY,s:scrollY};t.classList.add('drag');t.setPointerCapture(e.pointerId);e.preventDefault()});
  t.addEventListener('pointermove',e=>{if(!drag)return;const H=innerHeight,SH=document.documentElement.scrollHeight,h=Math.max(40,H*H/SH);
    scrollTo(0,drag.s+(e.clientY-drag.y)*(SH-H)/(H-h))});
  const end=()=>{drag=null;t.classList.remove('drag');show()};t.addEventListener('pointerup',end);t.addEventListener('pointercancel',end);
  new MutationObserver(place).observe(app,{childList:true});place();
})();
fromHash();
