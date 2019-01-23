## testdata

This repo has files required by Google's unittests for Tesseract.

The unicharset files were provided by Ray Smith for unicharcompress_test.
These seem to be old format unicharsets, having ligatures as unichars.

lstm related unittests required unicharset and lstmf files 
for eng and kor using Arial font. Since the files were not provided
with the unittest sources, an attempt was made to recreate them
based on comments in lstm_test.cc. (See https://github.com/tesseract-ocr/test/issues/13)

Since these are based on different training_text than what was used 
at Google, some tweaking of tests was required to get the expected results.
(eg. number of training iterations were increased in some cases)
Filenames were changed to use the default names created by tesstrain.sh.
Use -xsize 800 with text2image command.

The following commands were used to create the required files and remove
the ones not needed by the unittests.

```
src/training/tesstrain.sh \
--fonts_dir /usr/share/fonts \
--lang eng \
--linedata_only   \
--noextract_font_properties \
--langdata_dir ../langdata_lstm  \
--tessdata_dir ../tessdata \
--output_dir ~/test/testdata \
--fontlist "Arial" --maxpages 10

rm ~/test/testdata/eng.training_files.txt
rm ~/test/testdata/eng/eng.charset_size*.txt
rm ~/test/testdata/eng/eng.traineddata

src/training/tesstrain.sh \
--fonts_dir /usr/share/fonts \
--lang kor \
--linedata_only   \
--noextract_font_properties \
--langdata_dir ../langdata_lstm  \
--tessdata_dir ../tessdata \
--output_dir ~/test/testdata \
--fontlist "Arial Unicode MS" --maxpages 10

rm ~/test/testdata/kor.training_files.txt
rm ~/test/testdata/kor/kor.charset_size*.txt
rm ~/test/testdata/kor/kor.traineddata
```
