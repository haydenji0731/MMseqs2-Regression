#!/bin/sh -e
MMSEQS="${1}"
EVALUATE="${2}"
DATADIR="${3}"
RESULTS="${4}"
mkdir -p "${RESULTS}"

QUERY="${DATADIR}/query.fasta"
QUERYDB="${RESULTS}/query"
"${MMSEQS}" createdb "${QUERY}" "${QUERYDB}"

TARGET="${DATADIR}/targetannotation.fasta"
TARGETDB="${RESULTS}/targetannotation"
"${MMSEQS}" createdb "${TARGET}" "${TARGETDB}"

"${MMSEQS}" mergedbs "${TARGETDB}" "${TARGETDB}_fasta" "${TARGETDB}_h" "$TARGETDB" --prefixes ">"
awk 'BEGIN { printf("%c%c%c%c",11,0,0,0); exit; }' > "${TARGETDB}_fasta.dbtype"
"${MMSEQS}" msa2profile "${TARGETDB}_fasta" "${TARGETDB}_profile" --filter-msa 0

"${MMSEQS}" search "$QUERYDB" "${TARGETDB}_profile" "$RESULTS/results_aln" "$RESULTS/tmp" -s 1 -e 10000
"${MMSEQS}" convertalis "$QUERYDB" "${TARGETDB}_profile" "$RESULTS/results_aln" "$RESULTS/results_aln.m8"

"${EVALUATE}" "$QUERY" "$TARGET" "$RESULTS/results_aln.m8" "${RESULTS}/evaluation_roc5.dat" 4000 1 | tee "${RESULTS}/evaluation.log"
ACTUAL=$(grep "^ROC5 AUC:" "${RESULTS}/evaluation.log" | cut -d" " -f3)
TARGET="0.142"
awk -v actual="$ACTUAL" -v target="$TARGET" \
    'BEGIN { print (actual >= target) ? "GOOD" : "BAD"; print "Expected: ", target; print "Actual: ", actual; }' \
    > "${RESULTS}/report"
