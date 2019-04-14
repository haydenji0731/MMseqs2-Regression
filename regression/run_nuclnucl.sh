#!/bin/sh -e
MMSEQS="${1}"
EVALUATE="${2}"
DATADIR="${3}"
RESULTS="${4}"
mkdir -p "${RESULTS}"

QUERY="${DATADIR}/query.fasta"
QUERYDB="${RESULTS}/query"
"${MMSEQS}" createdb "${QUERY}" "${QUERYDB}"
"${MMSEQS}" translateaa "${QUERYDB}" "${QUERYDB}_nucl"
ln -sf "${QUERYDB}_h" "${QUERYDB}_nucl_h"
ln -sf "${QUERYDB}_h.index" "${QUERYDB}_nucl_h.index"
ln -sf "${QUERYDB}_h.dbtype" "${QUERYDB}_nucl_h.dbtype"

TARGET="${DATADIR}/targetannotation.fasta"
TARGETDB="${RESULTS}/targetannotation"
"${MMSEQS}" createdb "${TARGET}" "${TARGETDB}"
"${MMSEQS}" translateaa "${TARGETDB}" "${TARGETDB}_nucl"
ln -sf "${TARGETDB}_h" "${TARGETDB}_nucl_h"
ln -sf "${TARGETDB}_h.index" "${TARGETDB}_nucl_h.index"
ln -sf "${TARGETDB}_h.dbtype" "${TARGETDB}_nucl_h.dbtype"

"${MMSEQS}" search "${QUERYDB}_nucl" "${TARGETDB}_nucl" "$RESULTS/results_aln" "$RESULTS/tmp" -e 10000 -s 1 --max-seqs 4000 -k 10 -a --search-type 3
"${MMSEQS}" convertalis "${QUERYDB}_nucl" "${TARGETDB}_nucl" "$RESULTS/results_aln" "$RESULTS/results_aln.m8" --search-type 3 
"${MMSEQS}" convertalis "${QUERYDB}_nucl" "${TARGETDB}_nucl" "$RESULTS/results_aln" "$RESULTS/results_aln.sam" --format-mode 1 --search-type 3 
samtools view -b -h "$RESULTS/results_aln.sam" > "$RESULTS/results_aln.bam"

"${EVALUATE}" "$QUERY" "$TARGET" "$RESULTS/results_aln.m8" "${RESULTS}/evaluation_roc5.dat" 4000 1 | tee "${RESULTS}/evaluation.log"
ACTUAL=$(grep "^ROC5 AUC:" "${RESULTS}/evaluation.log" | cut -d" " -f3)
TARGET="0.177"
awk -v actual="$ACTUAL" -v target="$TARGET" \
    'BEGIN { print (actual >= target) ? "GOOD" : "BAD"; print "Expected: ", target; print "Actual: ", actual; }' \
    > "${RESULTS}/report"
