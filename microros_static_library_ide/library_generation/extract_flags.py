import sys

text = sys.stdin.read().replace('\n', ' ').split(' ')

mcpu = [x for x in text if x.startswith("-mcpu")]
mfpu = [x for x in text if x.startswith("-mfpu")]
mfloatabi = [x for x in text if x.startswith("-mfloat-abi")]
mthumb = [x for x in text if x.startswith("-mthumb")]
optimization = [x for x in text if x.startswith("-O")]

out = "-ffunction-sections -fdata-sections"
if len(mcpu) and len(mfpu) and len(mfloatabi):
    out = out + " " + mcpu[0] + " " + mfpu[0] + " " + mfloatabi[0]
    if len(mthumb):
        out = out + " " + mthumb[0]
    if len(optimization):
        out = out + " " + optimization[0]
    print(out)
    sys.exit(0)
else:
    sys.exit(1)
