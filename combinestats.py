import sys

infile = sys.argv[1]
outfile = sys.argv[2]

stats = dict()

with open(infile, "r") as f:
    for line in f:
        dat = line.split("\t")
        if len(dat) < 3:
            continue
        desc = dat[0] + "\t" + dat[1]
        if desc not in stats:
            stats[desc] = int(dat[2])
        else:
            stats[desc] += int(dat[2])


f = open(outfile, "w")
for stat, value in stats.items():
    f.write(stat + "\t" + str(value) + "\n")
f.close()