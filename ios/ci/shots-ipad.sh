#!/bin/bash
# Capturas no simulador de iPad (passo separado, com limite de tempo, para nunca travar o resto do CI).
APP=$(find ios/build/Build/Products -name "LumiCatecismos.app" -maxdepth 3 | head -1)
B=br.com.lumi.catecismos
mkdir -p shots
shot() { name=$1; shift
  xcrun simctl launch --terminate-running-process "$UDID" $B "$@" >/dev/null
  sleep 5
  xcrun simctl io "$UDID" screenshot "shots/$name.png" >/dev/null 2>&1
  sips -Z 1400 "shots/$name.png" >/dev/null 2>&1 || true
}
xcrun simctl shutdown all || true
# ---- iPad ----
PAD=$(xcrun simctl list devices available -j | python3 -c "
import json,sys
d=json.load(sys.stdin)['devices']
c=[x for k,v in d.items() if 'iOS' in k for x in v if 'iPad' in x['name']]
want=['iPad Pro 11-inch (M5)','iPad Pro 11-inch (M4)','iPad Air 11-inch (M3)','iPad (A16)','iPad (10th generation)']
for w in want:
    for x in c:
        if x['name']==w: print(x['udid']); sys.exit()
print(c[0]['udid'] if c else '')")
if [ -n "$PAD" ]; then
  echo "iPad: $PAD"
  xcrun simctl boot "$PAD" || true
  xcrun simctl bootstatus "$PAD" -b
  xcrun simctl install "$PAD" "$APP"
  UDID=$PAD
  xcrun simctl ui "$UDID" appearance light
  shot ipad-hub -shot hub -demo
  shot ipad-book -shot book -book breve -demo
  shot ipad-quiz -shot quiz -demo -answer right
  shot ipad-class -shot class -demo
  xcrun simctl ui "$UDID" appearance dark
  shot ipad-dark-hub -shot hub -demo
  shot ipad-dark-book -shot book -book maior -demo
fi
echo "Capturas iPad:"; ls shots | grep ipad
