# Place this in: MyWebApp/Dockerfile
FROM tomcat:10.1.18-jdk17-temurin
RUN rm -rf /usr/local/tomcat/webapps/*
COPY target/ROOT.war /usr/local/tomcat/webapps/ROOT.war
EXPOSE 8080
CMD ["catalina.sh", "run"]
