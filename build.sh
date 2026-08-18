#!/bin/sh
# Сборка подсистемы Cuda в 64-битный мир BlackBox.
# Мир: $BBCP64USE (по умолчанию ~/sources/bbcp64use), репо bbcp: $BBCP.
# Идемпотентно: скелет Cuda/{Code,Sym} + симлинки Mod/Docu -> эта репа,
# sync .odc.txt -> .odc (OdcTextU.Batch в консоли BB64), компиляция dev0.
set -e
BBCP="${BBCP:-$HOME/sources/bbcp}"
USE="${BBCP64USE:-$HOME/sources/bbcp64use}"
HERE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

mkdir -p "$USE/Cuda/Code" "$USE/Cuda/Sym"
ln -sfn "$HERE/Mod" "$USE/Cuda/Mod"
ln -sfn "$HERE/Docu" "$USE/Cuda/Docu"

# sync .odc.txt -> .odc
BATCH=/tmp/odc-batch.txt	# имя захардкожено в OdcTextU.Batch
rm -f "$BATCH"
n=0
for txt in "$HERE"/Mod/*.odc.txt; do
	odc="${txt%.txt}"
	if [ ! -e "$odc" ] || [ "$txt" -nt "$odc" ]; then
		printf 'I "%s" "%s"\n' "$txt" "$odc" >> "$BATCH"
		echo "sync: $txt"
		n=$((n + 1))
	fi
done
if [ "$n" -gt 0 ]; then
	out=$(cd "$USE" && echo 'OdcTextU.Batch' | BB_CONSOLE=1 BB_STANDARD_DIR="$USE" \
		timeout -k 5 300 "$BBCP/Dev/Rsrc/bbrun64" --console 2>&1)
	done_n=$(printf '%s\n' "$out" | grep -c '^Done! res:  0$' || true)
	rm -f "$BATCH"
	[ "$done_n" = "$n" ] || { echo "sync FAILED ($done_n of $n)" >&2; exit 1; }
fi

# компиляция (Dev прячем: 64-битные DevCP*.ocf ломают dev0)
STASH="$USE/.dev-stash-cuda"
[ -d "$USE/Dev" ] && mv "$USE/Dev" "$STASH"
trap '[ -d "$STASH" ] && mv "$STASH" "$USE/Dev"' EXIT
trap 'exit 1' INT TERM PIPE
cd "$USE"
printf '%s\n' CudaRt CudaUtil CudaBlas CudaFft CudaTest CudaTestBlas CudaTestFft > /tmp/compile1.txt
echo 'DevOnce.Go64' | "$BBCP/run-dev0" 2>&1 | grep -E 'compiling|err = |ERROR' | head -20
for m in Rt Util Blas Fft Test TestBlas TestFft; do
	[ -f "$USE/Cuda/Code/$m.ocf" ] || { echo "build: Cuda$m — ocf не найден" >&2; exit 1; }
done
echo "build: Cuda ok"
