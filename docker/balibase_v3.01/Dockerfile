FROM pditommaso/dkrbase:1.2
LABEL maintainer="Jose Espinosa-Carrasco <espinosacarrascoj@gmail.com>"

## Install MView for file-format conversion
RUN apt-get install unzip

ENV MV_VERSION=1.67

RUN cd /opt/ &&\
 wget -q https://github.com/desmid/mview/archive/v$MV_VERSION.zip &&\
 unzip v${MV_VERSION} &&\
 rm -rf v${MV_VERSION}.zip &&\
 cd mview-${MV_VERSION} &&\
 sed -i -- 's/#\!\/usr\/bin\/env perl/\#\!\/usr\/bin\/perl/g' bin/mview &&\
 sed -i -- "s/\/home\/brown\/HOME\/work\/MView\/dev/\/opt\/mview-${MV_VERSION}/g" bin/mview 

ENV PATH "$PATH:/opt/mview-${MV_VERSION}/bin"

## Install bali_score
RUN wget -q http://www.lbgi.fr/balibase/BalibaseDownload/BAliBASE_R1-5.tar.gz &&\
 tar xf BAliBASE_R1-5.tar.gz &&\
 rm -rf BAliBASE_R1-5.tar.gz &&\
 cd bb3_release/bali_score_src && \
 rm -rf expat-1.95.2 &&\
# wget -q https://sourceforge.net/projects/expat/files/expat/2.0.1/expat-2.0.1.tar.gz/download &&\
 curl -L -o expat-2.0.1.tar.gz  https://sourceforge.net/projects/expat/files/expat/2.0.1/expat-2.0.1.tar.gz/download?use_mirror=netix &&\
 gunzip expat-2.0.1.tar.gz &&\
 tar xf expat-2.0.1.tar &&\
 sed -i -- 's/expat-1.95.2/expat-2.0.1/g' makefile &&\
 make &&\
 mkdir -p /opt/bali_score/bin &&\
 cp bali_score /opt/bali_score/bin &&\
 cd ../.. &&\
 rm -rf bb3_release

ENV PATH "$PATH:/opt/bali_score/bin"
