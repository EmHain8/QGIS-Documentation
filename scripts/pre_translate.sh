#!/bin/bash

LOCALES='fr de it ja pt ru es nl'

if [ $1 ]; then
  LOCALES=$1
fi

# Create / update the translation catalogue - this will generate the master .pot files
mkdir -p i18n/pot
# Create a (temporary) static directory in source to hold all (localised ) static content
mkdir -p source/static

BUILDDIR=build
# be sure to remove an old build dir
rm -rf ${BUILDDIR}
mkdir -p ${BUILDDIR}

# copy english resources to static to be able to do a proper sphinx-build
mkdir source/static
cp -r resources/en/* source/static/

sphinx-build -d ${BUILDDIR}/doctrees -b gettext source i18n/pot/

# Now iteratively update the locale specific .po files with any new strings needed translation

for LOCALE in ${LOCALES}
do
  echo "Updating translation catalog for ${LOCALE}:"
  echo "------------------------------------"
  mkdir -p i18n/${LOCALE}/LC_MESSAGES
  # cleanup images from static (different locales can have different localized images)
  rm -rf source/static/*
  # Clone the en resources and then overwrite with any localised versions of the same files.
  cp -r resources/en/* source/static/
  PODIR=resources/${LOCALE}
  if [ -d $PODIR ];
  then
      cp -r ${PODIR}/* source/static/
  fi

  # Merge or copy all the updated pot files over to locale specific po files
  for FILE in `find i18n/pot/ -type f`
  do
    POTFILE=${FILE}
    POFILE=`echo ${POTFILE} | sed -e 's,\.pot,\.po,' | sed -e 's,pot,'${LOCALE}'/LC_MESSAGES,'`
    if [ -f $POFILE ];
    then
      echo "Updating strings for ${POFILE}"
      msgmerge -U ${POFILE} ${POTFILE}
    else
      echo "Creating ${POFILE}"
      mkdir -p `echo $(dirname ${POFILE})`
      cp ${POTFILE} ${POFILE} 
    fi
  done
done

# Now get rid of temporary POT files
rm -rf i18n/pot
rm -rf source/static
