import sys
import random

infile = sys.argv[1]
outfile = sys.argv[2]
bygenus = False
if sys.argv[3] == "genus":
    bygenus = True
rseed = int(sys.argv[4])
numgenomes = int(sys.argv[5])

random.seed(rseed)

f = open(infile, "r")
dat = [x.split("\t") for x in f.read().split("\n") if len(x) > 0 and not x[0]=="#"]
dat = [x for x in dat if x[11] == "Complete Genome" or x[11] == "Chromosome"]
f.close()
print(len(dat))
orgs = dict()

for line in dat:
    org = line[7]
    if bygenus:
        org = org.split(" ")[0]
    if org not in orgs:
        orgs[org] = []
    orgs[org] += [line]

numwritten = 0
f = open(outfile, "w")
for org in orgs:
    selected = random.choice(orgs[org])
    url = selected[-4]
    f.write(url + "/" + url.split("/")[-1] + "_genomic.gbff.gz")
    f.write("\n")
    numwritten += 1
    if numwritten >= numgenomes:
        break
f.close()