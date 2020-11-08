Prerequisities
------------

Tesseract OCR should be installed and available from the command line. The trained models for Tesseract OCR should be present under the path `~/src/tessdata`, to change this path modify the variable `PATH_TESSDATA` in the source code of the utility.

There are example trained models available on GitHub:

https://github.com/tesseract-ocr/tessdata

https://github.com/tesseract-ocr/tessdata_best

https://github.com/tesseract-ocr/tessdata_fast

Running the utility
--------------

Extract text with `pdftotext`, from all pages of the PDF file `aaa.pdf`:
```bash
pdf2txt.sh aaa.pdf
```

Extract text with Tesseract OCR, from pages 5-14 of the PDF file `aaa.pdf` which contents are in English:
```bash
pdf2txt.sh -f 5 -t 14 -l eng -m tesseract aaa.pdf
``` 

This utility might fail if there are whitespaces present in the paths or filenames.
