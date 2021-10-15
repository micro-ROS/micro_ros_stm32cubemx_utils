import sys

text = sys.stdin.read().replace('\n', ' ').split(' ')

mcpu = [x for x in text if x.startswith("-mcpu")]
mfpu = [x for x in text if x.startswith("-mfpu")]
mfloatabi = [x for x in text if x.startswith("-mfloat-abi")]
mthumb = [x for x in text if x.startswith("-mthumb")]
optimization = [x for x in text if x.startswith("-O")]
specs = [x for x in text if x.startswith("--specs")]

defines = [x for x in text if x.startswith("-D")]
defines = list(set(defines))

includes = [x for x in text if x.startswith("-I")]
includes = list(set(includes))
includes = [x.replace("../", "/project/") for x in includes]

out = "-ffunction-sections -fdata-sections -DSTM32CUBEIDE"

# This fix is needed for the embeddedRTPS to work due to the lack of include
# <sys/errno.h> in Middlewares/Third_Party/LwIP/src/include/lwip/errno.h
out = out + " -DENOTSUP=1 -DECANCELED=1 -DEOWNERDEAD=1 -DENOTRECOVERABLE=1"

if len(mcpu) and len(mfloatabi):
    out = out + " " + mcpu[0] + " " + mfloatabi[0]
    if len(mthumb):
        out = out + " " + mthumb[0]
    if len(mfpu):
        out = out + " " + mfpu[0]
    if len(optimization):
        out = out + " " + optimization[0]
    if len(defines):
        out = out + " " + " ".join(defines)
    if len(specs):
        out = out + " " + specs[0]
    if len(includes):
        out = out + " " + " ".join(includes)
    print(out)
    sys.exit(0)
else:
    sys.exit(1)
