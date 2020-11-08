#!/bin/sh

PATH_TESSDATA=$HOME/src/tessdata

DEFAULT_PAGE_FROM=1
DEFAULT_PAGE_TO=1
DEFAULT_RESOLUTION=300
DEFAULT_LANGUAGE=eng
DEFAULT_MODE=pdftotext

ARG_PAGE_FROM=-1
ARG_PAGE_TO=-1
ARG_RESOLUTION=-1
ARG_LANGUAGE=""
ARG_FILENAME=""
ARG_MODE=""

CONFIG_PAGE_FROM=-1
CONFIG_PAGE_TO=-1
CONFIG_RESOLUTION=-1
CONFIG_LANGUAGE=""
CONFIG_FILENAME=""
CONFIG_FILENAME_PREFIX=""
CONFIG_MODE=""

FILE_FIRST_PAGE=-1
FILE_LAST_PAGE=-1

while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -f|--from)
    ARG_PAGE_FROM="$2"
    shift # past argument
    shift # past value
    ;;
    -t|--to)
    ARG_PAGE_TO="$2"
    shift # past argument
    shift # past value
    ;;
    -r|--resolution)
    ARG_RESOLUTION="$2"
    shift # past argument
    shift # past value
    ;;
    -l|--language)
    ARG_LANGUAGE="$2"
    shift # past argument
    shift # past value
    ;;
    -m|--mode)
    ARG_MODE="$2"
    shift # past argument
    shift # past value
    ;;
    *)
    ARG_FILENAME="$1"
    shift
esac
done

requirements ()
{
    type pdfinfo
    type grep
    type tr
    type cut
    if [[ $ARG_MODE = "tesseract" ]];then
        type convert
        type tesseract
    fi
}

usage ()
{
    echo 'Usage: pdf2txt -f|--from [START_PAGE] -t|--to [END_PAGE] -r|--resolution [RESOLUTION] -l|--language [LANGUAGE] -m|--mode [EXTRACTION_MODE] [SOURCE_FILENAME]'
    echo '[START_PAGE] the page number of the first page of PDF file'
    echo '[END_PAGE] the page number of the last page of the PDF file'
    echo '[RESOLUTION] the resolution the scanner used'
    echo '[LANGUAGE] 3-letter language code'
    echo '[EXTRACTION_MODE] "tesseract" or "pdftotext"'
    echo '[SOURCE_FILE] file name of the PDF file'
}


input_validate ()
{
    if [[ -e "$ARG_FILENAME" ]];then
        CONFIG_FILENAME=$ARG_FILENAME
        filename_extension="${CONFIG_FILENAME##*.}"
        CONFIG_FILENAME_PREFIX=$(echo "$CONFIG_FILENAME" | sed -e "s/.$filename_extension\$//g")
        pdf_find_pages
    else
        echo "[✗] Input file doesn't exist."
        usage
        exit 1
    fi
    if [[ "$ARG_PAGE_FROM" =~ ^[0-9]+$ ]];then
        CONFIG_PAGE_FROM=$ARG_PAGE_FROM
    else
        CONFIG_PAGE_FROM=$FILE_FIRST_PAGE
    fi
    if [[ "$ARG_PAGE_TO" =~ ^[0-9]+$ ]];then
        CONFIG_PAGE_TO=$ARG_PAGE_TO
    else
        CONFIG_PAGE_TO=$FILE_LAST_PAGE
    fi
    if [[ "$ARG_RESOLUTION" =~ ^[0-9]+$ ]];then
        CONFIG_RESOLUTION=$ARG_RESOLUTION
    else
        CONFIG_RESOLUTION=$DEFAULT_RESOLUTION
    fi
    if [[ "$ARG_MODE" =~ ^(tesseract|pdftotext)$ ]];then
        CONFIG_MODE=$ARG_MODE
    else
        CONFIG_MODE=$DEFAULT_MODE
    fi
    if [[ $CONFIG_MODE = "tesseract" ]];then
        CONFIG_LANGUAGE=$(echo "$ARG_LANGUAGE" | tr '[:upper:]' '[:lower:]')
        lang_supported=$( \
            env TESSDATA_PREFIX=$PATH_TESSDATA tesseract --list-langs | \
            grep -ws $CONFIG_LANGUAGE \
        )
        if [[ $lang_supported = "" ]];then
            echo \
                "[✗] The language "\
                $ARG_LANGUAGE\
                " is not supported by Tesseract installation, falling back to "\
                $DEFAULT_LANGUAGE
            CONFIG_LANGUAGE=$DEFAULT_LANGUAGE
        fi
        if [[ $lang_supported = $CONFIG_LANGUAGE ]]; then
            echo "[✔] The language "$CONFIG_LANGUAGE" is supported by Tesseract installation"
        fi
    fi
}

pdf_find_pages ()
{
    FILE_FIRST_PAGE=1
    FILE_LAST_PAGE=$(pdfinfo "$ARG_FILENAME" | grep -i pAgEs: | tr -d " " | cut -d ":" -f2-)
}

extract_tesseract ()
{
    echo "[→] OCR-ing pages "$CONFIG_PAGE_FROM" to "$CONFIG_PAGE_TO
    for i in `seq $CONFIG_PAGE_FROM $CONFIG_PAGE_TO`; do
        index_padded=$(printf %04d $i)
        filename_page=$CONFIG_FILENAME_PREFIX-$index_padded
#        convert -alpha remove -density $CONFIG_RESOLUTION -white-threshold 80% $CONFIG_FILENAME\[$(($i - 1 ))\] $filename_page.tiff
        convert -alpha remove -density $CONFIG_RESOLUTION $CONFIG_FILENAME\[$(($i - 1 ))\] $filename_page.tiff
        convert -monochrome $filename_page.tiff $filename_page.tiff
        echo -en "\rProcessing page $index_padded/$CONFIG_PAGE_TO from the file $CONFIG_FILENAME"
        env TESSDATA_PREFIX=$PATH_TESSDATA tesseract -l $CONFIG_LANGUAGE $filename_page.tiff $filename_page
    done
    exit 0
}

extract_pdftotext ()
{
    echo "[→] Extracting text from pages "$CONFIG_PAGE_FROM" to "$CONFIG_PAGE_TO
    for i in `seq $CONFIG_PAGE_FROM $CONFIG_PAGE_TO`; do
        index_padded=$(printf %04d $i)
        echo -en "\rProcessing page $index_padded/$CONFIG_PAGE_TO from the file $CONFIG_FILENAME"
#        pdftotext -layout -f $i -l $i -r $CONFIG_RESOLUTION $CONFIG_FILENAME $CONFIG_FILENAME_PREFIX-$index_padded.txt
        pdftotext -f $i -l $i -r $CONFIG_RESOLUTION $CONFIG_FILENAME $CONFIG_FILENAME_PREFIX-$index_padded.txt
    done
    exit 0
}

extract_text ()
{
    if [[ $CONFIG_MODE = "tesseract" ]];then
        extract_tesseract
    fi
    if [[ $CONFIG_MODE = "pdftotext" ]];then
        extract_pdftotext
    fi
}


function run ()
{
    requirements
    input_validate
    extract_text
}

run
