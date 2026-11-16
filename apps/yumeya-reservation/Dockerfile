# Build the existing Servlet/JSP application; no credentials are baked into this image.
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml ./
COPY src/ ./src/
RUN mvn -B -ntp clean package

# Tomcat 9 is required by this codebase's javax.servlet imports.
FROM tomcat:9.0-jre17-temurin-noble
ENV JAVA_OPTS="-Xms64m -Xmx256m -XX:MaxMetaspaceSize=128m -Dfile.encoding=UTF-8"
RUN rm -rf /usr/local/tomcat/webapps/*
COPY --from=build /app/target/yumeya-reservation.war /usr/local/tomcat/webapps/ROOT.war
COPY docker/entrypoint.sh /usr/local/bin/yumeya-entrypoint.sh
RUN chmod 755 /usr/local/bin/yumeya-entrypoint.sh \
  && groupadd --gid 10001 appuser \
  && useradd --uid 10001 --gid appuser --home-dir /usr/local/tomcat --shell /usr/sbin/nologin appuser \
  && chown -R appuser:appuser /usr/local/tomcat
USER appuser
EXPOSE 10000
ENTRYPOINT ["/usr/local/bin/yumeya-entrypoint.sh"]
