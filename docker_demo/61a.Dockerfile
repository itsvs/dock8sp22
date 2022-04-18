# main dev happens in python, so use the python base image
FROM python:buster

# update pip and the apt package registry, then install latex
RUN pip install -U pip && pip install pipenv
RUN apt-get update \
  && apt install -y --no-install-recommends texlive-full \
  && apt-get install -y latexmk
RUN apt-get update && apt-get install -y rsync

# install some utilities
RUN apt-get install -y curl git vim nginx zip \
  && apt-get install -y make build-essential groff

# install build dependencies (node, pandoc, wkhtmltopdf)
RUN apt-get update && apt-get install -y nodejs npm
RUN npm install --global yarn sass serve
RUN apt-get update && apt-get install -y pandoc
RUN apt-get update && apt-get install -y wkhtmltopdf

# copy _just_ python requirements first, to aid with caching
COPY requirements.txt ./requirements.txt
RUN pip install -r requirements.txt && pip install buildtool

# copy the repository after all installations are done
COPY . .