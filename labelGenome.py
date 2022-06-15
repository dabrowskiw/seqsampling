import gzip
import sys
from Bio import SeqIO

infile = sys.argv[1]
outfile = sys.argv[2]
statsfile = sys.argv[3]

gb = SeqIO.parse(gzip.open(infile, "rt"), "genbank")
records = [x for x in gb]

meanings = [
    "Hypothetical",
    "Reverse",
    "Forward"
]

stats = 8*[0]

f = open(outfile, "w")
for record in records:
    labels = [0]*len(record.seq)
    # For each feature, add the appropriate bitmask
    # Bitmask is 3 bits long: 
    # | Bit number | Meaning      |
    # |------------|--------------|
    # |          1 | Forward CDS  |
    # |          2 | Reverse CDS  |
    # |          3 | Hypothetical |
    # 
    # Examples:
    # 100 (dec. 4): Base is in a forward CDS
    # 011 (dec. 3): Base is in reverse CDS, marked as hypothetical
    # 110 (dec. 6): Base is in both forward and reverse CDS
    # 000: Base is not in a CDS at all
    # 001: Base is not in a CDS, but marked as hypothetical -> Wojtek fucked up, go kick him ;)
    for feature in record.features:
        if feature.type != "CDS":
            # If not a CDS, leave the bitmask at 0
            continue
        for pos in feature.location.parts:
            startpos = min(pos.start.position, pos.end.position)
            featurelen = abs(pos.start.position-pos.end.position)
            # Forward strand: 01, reverse strand: 10
            featureval = 0b100
            if feature.strand == -1:
                featureval = 0b010
            for index in range(startpos, startpos+featurelen):
                labels[index] |= featureval
    # Set the last bit to 1 if the CDS is a hypothetical protein
    for feature in record.features:
        if feature.type != "CDS":
            continue
        if "product" not in feature.qualifiers:
            continue
        if "ypothetical" not in feature.qualifiers["product"][0]:
            continue
        for pos in feature.location.parts:
            startpos = min(pos.start.position, pos.end.position)
            featurelen = abs(pos.start.position-pos.end.position)
            for index in range(startpos, startpos+featurelen):
                labels[index] |= 1
    for index in range(0, len(labels)):
        try:
            stats[labels[index]] += 1
        except:
            print(labels[index])

    labelstring = "".join([chr(33+x) for x in labels])
    f.write(">" + record.name + " " + record.description)
    f.write("\n")
    f.write(str(record.seq))
    f.write("\n")
    f.write("+")
    f.write("\n")
    f.write(labelstring)
    f.write("\n")

f.close()

f = open(statsfile, "w")
for mask in range(0, len(stats)):
    bitnums = []
    for num in range(0, 3):
        if (mask & 2**num) != 0:
            bitnums += [num]
    description = ", ".join([meanings[x] for x in bitnums])
    if mask == 0:
        description = "Nothing"
    f.write("{:0>3b}\t{}\t{}\n".format(mask, description, stats[mask]))