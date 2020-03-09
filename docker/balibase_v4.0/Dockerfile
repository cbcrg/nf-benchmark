#  Copyright (c) 2020, Centre for Genomic Regulation (CRG).
#  Copyright (c) 2020, Jose Espinosa-Carrasco and the respective authors.
FROM pditommaso/dkrbase:1.2
MAINTAINER Jose Espinosa-Carrasco <espinosacarrascoj@gmail.com>

RUN apt-get install unzip

## Install mview to convert formats
RUN cd usr/local/ &&\
 wget -q https://github.com/desmid/mview/archive/master.zip &&\
 unzip master.zip &&\
 rm -rf master.zip &&\
 cd mview-master &&\
 perl install.pl /usr/local/bin

RUN wget http://www.lbgi.fr/balibase/BalibaseDownload/BAliBASE_R10_bali_score.tar.gz && \
    tar -xzf BAliBASE_R10_bali_score.tar.gz && \
    rm BAliBASE_R10_bali_score.tar.gz

RUN cd bali_score_src && \
    curl -L -o expat-2.0.1.tar.gz  https://sourceforge.net/projects/expat/files/expat/2.0.1/expat-2.0.1.tar.gz/download?use_mirror=netix &&\
    gunzip expat-2.0.1.tar.gz &&\
    tar xf expat-2.0.1.tar

RUN cd /bali_score_src/expat-2.0.1 &&\
    ./configure && \
    make && \
    make install

COPY util.c bali_score_src/util.c

RUN cd /bali_score_src && \
    sed -i -- 's/expat-1.95.6/expat-2.0.1/g' makefile &&\
    make clean && \
    make -f makefile

ENV PATH="/bali_score_src:${PATH}"
