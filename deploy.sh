#!/bin/bash
set -e

BUCKET="${1}"
VPATCH=`cut -d. -f1,2,3 VERSION`
VMINOR=`cut -d. -f1,2 VERSION`
VMAJOR=`cut -d. -f1 VERSION`

if aws s3 ls "s3://${BUCKET}/js/${VPATCH}/mapzen.min.js"; then
    echo "s3://${BUCKET}/js/${VPATCH}/mapzen.min.js already exits, checking diffs..."
    aws s3 cp --recursive --quiet "s3://static-prod.mapzen.com/js/${VPATCH}" "live-${VPATCH}"

    for NAME in mapzen.min.js mapzen.js mapzen.css images; do
        if diff -rq "dist/${NAME}" "live-${VPATCH}/${NAME}"; then
            echo "No differences between dist/${NAME} and live-${VPATCH}/${NAME}"
        else
            echo "Refusing to deploy due to a difference between dist/${NAME} and live-${VPATCH}/${NAME}"
            exit 0
        fi
    done
else
    echo "Nothing found at s3://${BUCKET}/js/${VPATCH}/mapzen.min.js"
fi

tar -czf dist/docs.tar.gz docs

for DIR in "js/${VPATCH}" "js/${VMINOR}" "js/${VMAJOR}" "js"; do
    aws s3 cp dist/docs.tar.gz s3://${BUCKET}/${DIR}/docs.tar.gz
    aws s3 cp dist/mapzen.min.js s3://${BUCKET}/${DIR}/mapzen.min.js
    aws s3 cp dist/mapzen.js s3://${BUCKET}/${DIR}/mapzen.js
    aws s3 cp dist/mapzen.css s3://${BUCKET}/${DIR}/mapzen.css
    aws s3 cp --recursive dist/images s3://${BUCKET}/${DIR}/images
done
