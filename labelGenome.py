import gzip
import sys
from Bio import SeqIO

infile = sys.argv[1]
outfile = sys.argv[2]

gb = SeqIO.parse(gzip.open(infile, "rt"), "genbank")
records = [x for x in gb]
f = open(outfile, "w")
for record in records:
    labels = [0]*len(record.seq)
    # For each feature, add the appropriate bitmask
    for feature in record.features:
        if feature.type != "CDS":
            # If not a CDS, leave the bismask at 0
            continue
        for pos in feature.location.parts:
            startpos = min(pos.start.position, pos.end.position)
            featurelen = abs(pos.start.position-pos.end.position)
            # Forward strand: 01, reverse strand: 10
            featureval = 1
            if feature.strand == -1:
                featureval = 2
            for index in range(startpos, startpos+featurelen):
                labels[index] = (labels[index] << 2) | featureval
    # Make space in the last bit for the "hypothetical" bit
    for index in range(0, len(record.seq)):
        labels[index] = labels[index] << 1
    maxval = 0
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
                labels[index] = (labels[index] | 1)
                if labels[index] > maxval:
                    maxval = labels[index]

    labelstring = "".join([chr(33+x) for x in labels])
    f.write(">" + record.name + " " + record.description)
    f.write("\n")
    f.write(str(record.seq))
    f.write("\n")
    f.write("+")
    f.write(labelstring)
    f.write("\n")

f.close()

print("Max char written: " + chr(maxval+33))