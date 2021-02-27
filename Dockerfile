FROM gcr.io/deeplearning-platform-release/pytorch-cpu

RUN apt-get update && apt-get install -y software-properties-common
RUN add-apt-repository ppa:ubuntugis/ppa && apt-get update && apt-get install -y gdal-bin libgdal-dev
ARG CPLUS_INCLUDE_PATH=/usr/include/gdal
ARG C_INCLUDE_PATH=/usr/include/gdal

RUN pip install GDAL==2.2.3

WORKDIR /home/jupyter

COPY requirements.txt ./requirements.txt
RUN pip install -r requirements.txt

RUN git clone https://github.com/NRCan/geo-deep-learning.git
