FROM perl:5.36-slim AS build
WORKDIR /snake
COPY cpanfile .
RUN apt-get update -y && apt-get upgrade -y
RUN cpan -I App::cpanminus
RUN cpanm --installdeps .

FROM build
COPY . .
EXPOSE 5000
CMD ["plackup", "--server Starman", "app.pl"]
