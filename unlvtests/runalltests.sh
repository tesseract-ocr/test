#!/bin/bash
# File:        runalltests.sh
# Description: Script to run a set of UNLV test sets for English.
# Author:      Ray Smith
#
# (C) Copyright 2007, Google Inc.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

if [ $# -ne 3 ]
then
   echo "Usage:$0 unlv-data-dir version-id tessdata-dir"
   exit 1
fi
if [ ! -d src/api ]
then
  echo "Run $0 from the tesseract-ocr root directory!"
  exit 1
fi
if [ ! -r tesseract ] && [ ! -r tesseract.exe ]
then
  echo "Please build tesseract before running $0"
  exit 1
fi
tessdata=$3

#deltapc new old calculates the %change from old to new
deltapc() {
awk ' BEGIN {
printf("%.2f", 100.0*('"$1"'-'"$2"')/'"$2"');
}'
}

#timesum computes the total cpu time
timesum() {
awk ' BEGIN {
total = 0.0;
}
{
  total += $2;
}
END {
  printf("%.2f\n", total);
}' "$1"
}

imdir="$1"
vid="$2"
bindir=${0%/*}
if [ "$bindir" = "$0" ]
then
    bindir="./"
fi
rdir=unlvtests/reports

testsets="bus.3B doe3.3B mag.3B news.3B"
#testsets="bus.3B"

totalerrs=0
totalwerrs=0
totalnswerrs=0
totalolderrs=0
totaloldwerrs=0
totaloldnswerrs=0
for set in $testsets
do
    if [ -r "$imdir/$set/pages" ]
    then
	# Run tesseract on all the pages.
	$bindir/runtestset.sh "$imdir/$set/pages" "$tessdata" "eng"
	# Count the errors on all the pages.
	$bindir/counttestset.sh "$imdir/$set/pages" "eng"
	# Get the old character word and nonstop word errors.
	olderrs=$(cut -f3 "unlvtests/reports/1995.$set.sum")
	oldwerrs=$(cut -f6 "unlvtests/reports/1995.$set.sum")
	oldnswerrs=$(cut -f9 "unlvtests/reports/1995.$set.sum")
	# Get the new character word and nonstop word errors and accuracy.
	cherrs=$(head -4 "unlvtests/results/$set.characc" |tail -1 |cut -c1-9 |
	    tr -d '[:blank:]')
	chacc=$(head -5 "unlvtests/results/$set.characc" |tail -1 |cut -c1-9 |
	    tr -d '[:blank:]')
	wderrs=$(head -4 "unlvtests/results/$set.wordacc" |tail -1 |cut -c1-9 |
	    tr -d '[:blank:]')
	wdacc=$(head -5 "unlvtests/results/$set.wordacc" |tail -1 |cut -c1-9 |
	    tr -d '[:blank:]')
	nswderrs=$(grep Total "unlvtests/results/$set.wordacc" |head -2 |tail -1 |
	    cut -c10-17 |tr -d '[:blank:]')
	nswdacc=$(grep Total "unlvtests/results/$set.wordacc" |head -2 |tail -1 |
	    cut -c19-26 |tr -d '[:blank:]')
	# Compute the percent change.
	chdelta=$(deltapc "$cherrs" "$olderrs")
	wdelta=$(deltapc "$wderrs" "$oldwerrs")
	nswdelta=$(deltapc "$nswderrs" "$oldnswerrs")
	sumfile=$rdir/$vid.$set.sum
        if [ -r "unlvtests/results/$set.times" ]
        then
          total_time=$(timesum "unlvtests/results/$set.times")
          if [ -r "unlvtests/results/prev/$set.times" ]
          then
            paste "unlvtests/results/prev/$set.times" "unlvtests/results/$set.times" |
              awk '{ printf("%s %.2f\n", $1, $4-$2); }' |sort -k2n >"unlvtests/results/$set.timedelta"
          fi
	else
          total_time='0.0'
        fi
        echo "$vid	$set	$cherrs	$chacc	$chdelta%	$wderrs	$wdacc\
	$wdelta%	$nswderrs	$nswdacc	$nswdelta%	${total_time}s" >"$sumfile"
	# Sum totals over all the testsets.
	let totalerrs=totalerrs+cherrs
	let totalwerrs=totalwerrs+wderrs
	let totalnswerrs=totalnswerrs+nswderrs
	let totalolderrs=totalolderrs+olderrs
	let totaloldwerrs=totaloldwerrs+oldwerrs
	let totaloldnswerrs=totaloldnswerrs+oldnswerrs
    fi
done
# Compute grand total percent change.
chdelta=$(deltapc $totalerrs $totalolderrs)
wdelta=$(deltapc $totalwerrs $totaloldwerrs)
nswdelta=$(deltapc $totalnswerrs $totaloldnswerrs)
tfile=$rdir/$vid.total.sum
echo "$vid	Total	$totalerrs	-	$chdelta%	$totalwerrs\
	-	$wdelta%	$totalnswerrs	-	$nswdelta%" >"$tfile"
cat $rdir/1995.*.sum "$rdir/$vid".*.sum >"$rdir/$vid".summary

mv "$rdir/$vid".*.sum unlvtests/results/
cat "$rdir/$vid".summary
