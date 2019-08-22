#!/bin/bash
function init_repo {
        ADMIN_EMAIL=dspace@lindat.cz
        IMPORT_DEF=dspace-import-structure.xml
        IMPORT_OUTPUT=/tmp/import_output.xml
        dspace database migrate
        dspace create-administrator -e "$ADMIN_EMAIL" -f "Mr." -l "Lindat" -p "dspace" -c "en"
        dspace structure-builder -f $IMPORT_DEF -o $IMPORT_OUTPUT -e "$ADMIN_EMAIL"
        dspace dsrun cz.cuni.mff.ufal.dspace.runnable.InitTemplates
}

function deploy_repo {
        pushd /srv/dspace-src/utilities/project_helpers/scripts
        make deploy_guru || true
        popd
}
cp variable.makefile /srv/dspace-src/utilities/project_helpers/config/
if readlink -e /srv/dspace/bin/dspace > /dev/null;then
        init_repo;
else
        sudo ln -s /srv/dspace/bin/dspace /usr/bin/dspace
        deploy_repo;
        init_repo;
fi
