#!/bin/sh -e
QUERY="${DATADIR}/query.fasta"
QUERYDB="${RESULTS}/query"
"${MMSEQS}" createdb "${QUERY}" "${QUERYDB}"

TARGET="${DATADIR}/targetannotation.fasta"
TARGETDB="${RESULTS}/targetannotation"
"${MMSEQS}" createdb "${TARGET}" "${TARGETDB}"

"${MMSEQS}" search "${TARGETDB}" "${TARGETDB}" "${RESULTS}/aln_target_profile" "${RESULTS}/tmp" 
"${MMSEQS}" result2profile "${TARGETDB}" "${TARGETDB}" "${RESULTS}/aln_target_profile" "${RESULTS}/target_profile"

"${MMSEQS}" search "${QUERYDB}" "${TARGETDB}" "${RESULTS}/aln_query_target" "${RESULTS}/tmp"
"${MMSEQS}" result2profile "${QUERYDB}" "${TARGETDB}" "${RESULTS}/aln_query_target" "${RESULTS}/query_profile"

"{MMSEQS}" prefilter "${QUERYDB}" "${TARGETDB}" "${RESULTS}/perf_query_target" 

"${MMSEQS}" align "${RESULTS}/query_profile" "${RESULTS}/target_profile" "${RESULTS}/perf_query_target" "${RESULTS}/results_aln" 
"${MMSEQS}" convertalis "${RESULTS}/query_profile" "${RESULTS}/target_profile" "${RESULTS}/results_aln" "${RESULTS}/results_aln.m8"

"${EVALUATE}" "$QUERY" "$TARGET" "$RESULTS/results_aln.m8" "${RESULTS}/evaluation_roc5.dat" 4000 1 | tee "${RESULTS}/evaluation.log"
ACTUAL=$(grep "^ROC5 AUC:" "${RESULTS}/evaluation.log" | cut -d" " -f3)
TARGET="0.231634"
awk -v actual="$ACTUAL" -v target="$TARGET" \
    'BEGIN { print (actual >= target) ? "GOOD" : "BAD"; print "Expected: ", target; print "Actual: ", actual; }' \
    > "${RESULTS}.report"
exit 1;
