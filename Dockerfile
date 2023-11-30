FROM perl:5.36 AS build
WORKDIR /snake
COPY cpanfile .
RUN apt-get update -y && apt-get upgrade -y
RUN cpan -I App::cpanminus
RUN cpanm -n --installdeps .

FROM build
COPY . .
EXPOSE 5000
ENV SNAKE_PRODUCTION=1
# I LOVE PERL!
CMD ["plackup", "--server", "Starman", "app.pl"]
