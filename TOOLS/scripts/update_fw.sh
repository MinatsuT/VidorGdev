if [ `quartus_sh --version | grep Lite | wc -l` == "1" ]; then
# compile for lite version
if [ -z $FORCE_FULL ]; then
LITE="_lite"
fi
fi

PROJECT_NAME=${PWD##*/}
source build_sw.sh

PROJECT_NAME=${PROJECT_NAME}$LITE

cd build
quartus_cdb --update_mif ${PROJECT_NAME}
quartus_asm ${PROJECT_NAME}
cd ..

source create_image.sh