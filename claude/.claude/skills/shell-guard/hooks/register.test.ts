import type { On } from 'claude-code'
import type { Engine } from 'claude-code/testing'
import { describe, expect, test } from 'claude-code/testing'

function engineRuns(on: On): string[] {
  const ran: string[] = []
  on('tool.call', ($, e) => {
    if (e.tool === 'Bash') ran.push(e.command)
    return { result: 'ok' }
  })
  return ran
}

async function bash($: Engine, command: string): Promise<void> {
  await $.tool.call({ tool: 'Bash', command })
}

const DENIED = [
  'SP=/tmp/claude-1000/x/scratchpad; rm -rf "$SP/$NAME"',
  'rm -r $OUT',
  'rm -r -f "$f"',
  'rm --recursive --force "$f"',
  'ls > "$SP/out.txt"',
  'ls > /tmp/x/$f',
  'make 2> ${LOG}',
  'make &> "$LOG"',
  'ls >| "$f"',
  "cd /home/pontusc/repo && python3 - <<'EOF'\nfrom pathlib import Path\nPath('order-db.yml').write_text(data)\nEOF",
  "python3 - <<'EOF'\nwith open('plan.md', 'w') as f:\n    f.write(text)\nEOF",
  "cat > progress.md <<'EOF'\n# Progress\nEOF",
  "cat <<EOF >> /home/pontusc/notes.md\nline\nEOF",
  'for d in */; do rm -rf "$d"; done',
  'if true; then\n  sudo rm -R "$d"\nfi',
  "python3 - <<'EOF'\nimport os\nopen(os.path.join(d, 'f'), 'wt').write(x)\nEOF",
  "cat > /tmp/a <<'EOT'\nx\nEOT\ncat > notes.md <<'EOT'\ny\nEOT",
  'cat <<EOT 2>/dev/null > out.md\nline\nEOT',
  `for c in a b; do kubectl get x "$c" -o json | jq '.a["b"]' > /tmp/s/dev-$c.json; done`,
  'for f in a b; do python3 "$D/s.py" "$D/$f.html" > "/tmp/s/$f.txt"; done',
  "cd /tmp/s && cd /home/pontusc/repo && cat > a.sh <<'EOF'\nx\nEOF",
  "D=/home/pontusc/repo; cd $D && cat > a.sh <<'EOF'\nx\nEOF",
  "M=/home/pontusc/repo; cat > $M/a.sh <<'EOF'\nx\nEOF",
  "cat <<'EOF' | tee notes.md\nx\nEOF",
  "cat > 'notes.md' <<'EOF'\nx\nEOF",
  "cat > \"my notes.md\" <<'EOF'\nx\nEOF",
  "cat > dev/notes.md <<'EOF'\nx\nEOF",
  "python3 - <<'EOF' 2>/dev/null\nopen('a.md', 'w').write(s)\nEOF",
  'S=/tmp/x; for c in a b; do ls > $S/$c; done',
  'for r in a b; do rm -rf src-$r; done',
  "cat > notes.md <<'END-X'\nx\nEND-X",
  'cat <<END-X > /tmp/x/a\nx\nEND-X\nrm -rf $q',
  "cat <<'EOF' &> notes.md\nx\nEOF",
  "cat <<'EOF' &>> notes.md\nx\nEOF",
  "cat <<'EOF' 1>> notes.md\nx\nEOF",
  'echo $((1<<bits))\nrm -rf $q',
  "cd /tmp/s && pushd /home/pontusc/repo && cat > a.md <<'EOF'\nx\nEOF",
  "cd /tmp/s && python3 - <<'EOF'\np = '/home/pontusc/repo/a.yml'\nopen(p, 'w').write(open(p).read())\nEOF",
  "pushd /home/pontusc/repo && popd && cat > a.md <<'EOF'\nx\nEOF",
  "((cd /home/x && make) | tail)\ncat > notes.md <<'EOF'\nx\nEOF",
  'x=$(( (1+(2)) <<3 ))\nrm -rf $q',
  "cat <<'EOF' >| notes.md\nx\nEOF",
  "cd /tmp/s && python3 - <<'EOF'\nopen('/home/pontusc/repo/a.yml', 'r+').write(x)\nEOF",
]

const PASSED = [
  'rm -rf /tmp/claude-1000/x/scratchpad/plans',
  'SP=/tmp/claude-1000/x/scratchpad; rm -rf "$SP/plans"',
  'export D=/tmp/x && ls > "$D/out"',
  'D="$(mktemp -d)"; rm -rf "$D"',
  'rm $OUT',
  'for f in *.log; do rm -f "$f"; done',
  'make 2>> ${LOG}',
  'cmd >> "$LOG"',
  'echo x | tee -a "$SP/log"',
  'T=/tmp/claude-1000/types.d.ts; grep -n Bash $T',
  'make 2>&1 | tail',
  'git -C /home/pontusc/dotfiles log -1',
  'grep -rn rm $HOME/.bashrc',
  'jq -r .a <<<"$json"',
  "cat > /tmp/claude-1000/x/scratchpad/note.md <<'EOF'\nnote\nEOF",
  "python3 - <<'EOF'\nimport json\nprint(json.load(open('a.json')))\nEOF",
  "python3 - <<'EOF'\nopen('/tmp/claude-1000/x/scratchpad/out.json', 'w').write('{}')\nEOF",
  "git commit -F- <<'EOF'\nmessage\nEOF",
  '[[ $a > $b ]] && echo yes',
  "jq '.[] | select(.count > $min)' --argjson min 5 data.json",
  "grep -n 'foo -> $bar' src/x.php",
  "awk '{ print $1 > $NF }' file",
  'grep -rn tee $HOME/.bashrc',
  'echo "a; rm $HOME/x"',
  "cat > /tmp/claude-1000/s/run.sh <<'EOT'\nrm -f \"$tmp\"\necho \"$1\" > \"$out\"\nEOT",
  "git commit -F- <<'EOT'\nGuard: deny `> $SP/x` redirects\nEOT",
  "gh pr create --body \"$(cat <<'EOT'\n> $PATH quote\nEOT\n)\"",
  "cat <<'EOT' | jq 'select(.a > 1)'\n{}\nEOT",
  "rg -n \"cat <<'EOT'\" . > /tmp/claude-1000/s/results.txt",
  "python3 - <<'EOT'\nimport subprocess\nsubprocess.run(['ls'], stdout=open('/dev/null', 'w'))\nEOT",
  "python3 - <<'EOT'\nprint(open('a').read())\nEOT",
  "cd /tmp/s && cat > a.sh <<'EOF'\nx\nEOF",
  "cd /tmp/s\ncat > a.sh <<'EOF'\nx\nEOF",
  "D=/tmp/s; mkdir -p $D && cd $D && cat > a.sh <<'EOF'\nx\nEOF",
  "R=\"/tmp/s\"; cat > ${R}/u.go <<'EOF'\nx\nEOF",
  "S=/tmp/s; cd $S\ncat > a.md <<'EOF'\nx\nEOF",
  "D=/tmp/s\ncd $D && cat > a.md <<'EOF'\nx\nEOF",
  "cat > \"/tmp/x/a.md\" <<'EOF'\nx\nEOF",
  "SP=/tmp/x; cat > \"$SP/a.md\" <<'EOF'\nx\nEOF",
  "OUT=$(mktemp); cat > \"$OUT\" <<'EOF'\nx\nEOF",
  "cd '/tmp/s' && cat > a.md <<'EOF'\nx\nEOF",
  "SP=/tmp/s; D=$SP/w; cd $D && cat > a.md <<'EOF'\nx\nEOF",
  "cd /tmp/s && cd sub && cat > a.md <<'EOF'\nx\nEOF",
  'echo "<b>$name</b>"',
  'curl -d "<x>$VAL</x>" https://a',
  'echo "a>$b"',
  "gh pr create --title \"a->b\" --body \"$(cat <<'EOF'\nbody\nEOF\n)\"",
  "python3 - <<'EOF'\nprint(open('a').read().replace('b', 'a'))\nEOF",
  "python3 - <<'EOF'\nd = json.load(open('a.json')); print(d.get('k', 'x'))\nEOF",
  '# write > $OUT later\nls',
  'ls # > $OUT',
  "awk '\n{ print $1 > $NF }\n' f",
  'git commit -m "Subject\n\n> $note quoted"',
  'out="$(printf "%s > $HOME" a)"',
  "cat > /tmp/x/a.sh <<\\EOF\nrm -rf \"$d\"\nEOF",
  "cat > /tmp/x/a.sh <<'EOF'\n  EOF\nrm -rf \"$d\"\nEOF",
  "ls > out.txt; cat > /tmp/x/a <<'EOF'\nx\nEOF",
  'for f in a b; do echo > "$f"; done',
  "cd /tmp/s && python3 - <<'EOF'\nopen('a.py', 'w').write(s)\nEOF",
  "cat > /tmp/x/a.sh <<'END-SCRIPT'\nrm -rf \"$d\"\nEND-SCRIPT",
  "cat > /tmp/x/a.sh <<\"END.SH\"\nrm -rf \"$d\"\nEND.SH",
  "cat > /tmp/x/a.sh <<'1EOF'\nrm -rf \"$d\"\n1EOF",
  "git commit -F - <<'COMMIT-MSG'\nGuard: deny > $SP redirects\nCOMMIT-MSG",
  "cat > /tmp/x/a.sh <<-EOF\n\tls > $out\n\tEOF",
  "cd -P /tmp/s && cat > a.md <<'EOF'\nx\nEOF",
  "pushd /tmp/s && cat > a.md <<'EOF'\nx\nEOF",
  "cat <<'EOF' | sudo tee /etc/x\nx\nEOF",
  "kubectl exec -i pod -- tee /data/x.conf <<'EOF'\nx\nEOF",
  "S=/tmp/s/a.py; python3 - \"$S\" <<'EOF'\nopen(sys.argv[1], 'w').write(s)\nEOF",
  "cat > /tmp/x/a <<'EOF'\nx\nEOF\ncat > /tmp/x/b <<'EOF'\ny\nEOF",
  "cat <<'EOF' 2>> err.log > /tmp/x/a\nx\nEOF",
  "cd /home/pontusc/repo && cat <<'EOF' > /tmp/x/a 2>> build.log\nx\nEOF",
  "sudo tee /etc/x 2>> err.log > /dev/null <<'EOF'\nx\nEOF",
  "cat <<'EOF' > >(tee -a /tmp/x/log)\nx\nEOF",
  "cd /tmp/s; pushd /home/pontusc/repo && make; popd; cat > a.md <<'EOF'\nx\nEOF",
  "cd /tmp/s && (cd /home/pontusc/repo && make) && cat > a.md <<'EOF'\nx\nEOF",
  "cd /tmp/s && python3 - <<'EOF'\nsrc = open('/home/pontusc/repo/a.yml').read()\nopen('out.txt', 'w').write(src)\nEOF",
  'cat > /tmp/x/a.sh <<1EOF\nrm -rf "$d"\n1EOF',
  'cat > /tmp/x/a.sh <<!\nrm -rf "$d"\n!',
  'cat > /tmp/x/a.sh <<.\nls > $out\n.',
  'cat > /tmp/x/a.sh <<-1\n\trm -rf $d\n\t1',
  "echo $((1<<bits)) > /tmp/x/n; cat > /tmp/x/a <<'EOF'\nx\nEOF",
  "((cd /tmp/x && make) || true)\ncat > /tmp/x/gen.sh <<'EOF'\nn=$((n+1))\ncat > notes.md <<'X'\ny\nX\nEOF",
  'cat x $(( (a+(b)) << 2 )) > notes.md',
  'echo "$(( a > $b ))"',
  "cd /tmp/s; pushd /home/pontusc/repo && popd; cat > a.md <<'EOF'\nx\nEOF",
]

describe('shell-guard', () => {
  for (const command of DENIED) {
    test(`denies ${command.split('\n')[0]}`, async ($, on) => {
      const ran = engineRuns(on)
      await bash($, command)
      expect(ran).toEqual([])
    })
  }

  for (const command of PASSED) {
    test(`passes ${command.split('\n')[0]}`, async ($, on) => {
      const ran = engineRuns(on)
      await bash($, command)
      expect(ran).toEqual([command])
    })
  }
})
