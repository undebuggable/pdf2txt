Extract text from all pages of the PDF file `aaa.pdf` with `pdftotext`:
```bash
pdf2txt.sh aaa.pdf
```

Extract text by using Tesseract OCR. Use pages 5-14 of the PDF file `aaa.pdf` which contents are in English:
```bash
pdf2txt.sh -f 5 -t 14 -l eng -m tesseract aaa.pdf
``` 

Be gentle - no whitespaces in the paths nor filenames.
