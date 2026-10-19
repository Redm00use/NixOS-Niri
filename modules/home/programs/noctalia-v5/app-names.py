from pathlib import Path
import configparser,json,sys
out,home,user=Path(sys.argv[1]),Path(sys.argv[2]),sys.argv[3]
names={}
roots=[Path('/run/current-system/sw/share/applications'),Path('/etc/profiles/per-user')/user/'share/applications',home/'.local/share/applications',Path('/var/lib/flatpak/exports/share/applications')]
for root in roots:
    for p in root.glob('*.desktop'):
        c=configparser.ConfigParser(interpolation=None,strict=False)
        try:
            c.read(p);e=c['Desktop Entry'];name=e.get('Name[ru]',e.get('Name',p.stem))
            for key in [p.stem,e.get('StartupWMClass','')]:
                if key:names[key]=name;names[key.lower()]=name
        except Exception:pass
out.parent.mkdir(parents=True,exist_ok=True)
tmp=out.with_suffix('.tmp');tmp.write_text(json.dumps(names,ensure_ascii=False));tmp.replace(out)
