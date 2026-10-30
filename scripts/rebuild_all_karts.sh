# Rebuild the whole kart asset chain into assets/ and install it (RSTB chained through every step).
set -e
cd "$(dirname "$0")"
export PYTHONPATH=../.tools/kart-assets/python KART_BASE_PACK=../assets/kart-grip/romfs/Pack/Actor/SpObj_ControlStick_A_01.pack.zs
M="$HOME/Library/Application Support/Ryujinx/mods/contents/0100f2c0115b6000/KartLab_110/romfs"; T=System/Resource/ResourceSizeTable.Product.110.rsizetable.zs
python3 build_kart_grip.py --rstb "$M/$T" > /dev/null; prev=../assets/kart-grip/romfs/$T
for v in skl bds bike; do rm -rf ../assets/kart-variant-$v/romfs; python3 build_kart_variant.py $v --rstb $prev > /tmp/kv.log 2>&1 || { tail -3 /tmp/kv.log; exit 1; }; prev=../assets/kart-variant-$v/romfs/$T; done
python3 build_kart_rsdb.py --rstb $prev >/dev/null 2>&1; prev=../assets/kart-rsdb/romfs/$T
python3 build_kart_capsules.py --rstb $prev >/dev/null 2>&1; prev=../assets/kart-capsules/romfs/$T
python3 build_kart_chests.py --rstb $prev >/dev/null 2>&1; prev=../assets/kart-chests/romfs/$T
for d in kart-grip kart-variant-skl kart-variant-bds kart-variant-bike kart-rsdb kart-capsules kart-chests; do (cd ../assets/$d/romfs && find . -type f ! -name "*.rsizetable.zs" -exec sh -c 'mkdir -p "$1/$(dirname "$2")"; cp "$2" "$1/$2"' _ "$M" {} \;); done
cp $prev "$M/$T"; python3 check_mod_sizes.py | tail -1
