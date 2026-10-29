#!/bin/bash
# Abre o app no simulador de iPhone e tira uma captura de cada tela.
set -e
APP=$(find ios/build/Build/Products -name "LumiCatecismos.app" -maxdepth 3 | head -1)
UDID=$(xcrun simctl list devices available -j | python3 -c "
import json,sys
d=json.load(sys.stdin)['devices']
want=['iPhone 16 Pro','iPhone 15 Pro','iPhone 16','iPhone 15']
c=[x for k,v in d.items() if 'iOS' in k for x in v]
for w in want:
    for x in c:
        if x['name']==w: print(x['udid']); sys.exit()
print([x for x in c if 'iPhone' in x['name']][0]['udid'])")
echo "Simulador: $UDID"
xcrun simctl boot "$UDID" || true
xcrun simctl bootstatus "$UDID" -b
xcrun simctl install "$UDID" "$APP"
mkdir -p shots
B=br.com.lumi.catecismos
shot() { # nome, argumentos...
  name=$1; shift
  xcrun simctl launch --terminate-running-process "$UDID" $B "$@" >/dev/null
  sleep 5
  xcrun simctl io "$UDID" screenshot "shots/$name.png" >/dev/null 2>&1
  sips -Z 1000 "shots/$name.png" >/dev/null 2>&1 || true
}
xcrun simctl ui "$UDID" appearance light
shot hub -shot hub -demo
shot book-breve -shot book -book breve -demo
shot book-maior -shot book -book maior -demo
shot book-conf -shot book -book conf -demo
shot unit -shot unit -demo
shot study -shot study -demo
shot quiz -shot quiz -demo
shot quiz-right -shot quiz -demo -answer right
shot quiz-wrong -shot quiz -demo -answer wrong
shot complete -shot complete -demo
shot build -shot build -demo
shot conf-quiz -shot quiz -book conf -demo -answer wrong
shot result -shot result -demo
shot class -shot class -demo
shot text -shot text -demo
xcrun simctl ui "$UDID" appearance dark
shot dark-hub -shot hub -demo
shot dark-book -shot book -book maior -demo
shot dark-quiz -shot quiz -demo -answer right
echo "Capturas:"; ls shots
